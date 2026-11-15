Rust 链接同一份 C 库，以及一份用 C ABI 导出的 C++ 库。每种库都有静态链接和动态链接。构建在 Linux 容器里完成，脚本不区分 x86 和 arm。没有 `build.rs`。

```text
c/scale.h            结构体 ScaleArgs，C 和 C++ 共用这份布局
c/foo.c              testcall，以及用指针传入 ScaleArgs 的 testcall_scale
c/Makefile           编出 libfoo.a、libfoo.so，以及 call_rust、call_rust_static
cxx/bar.cpp          C++ 类 PassedValue，用 extern "C" 导出 testcall_cxx 和 testcall_scale_cxx
cxx/Makefile         编出 libbar.a、libbar.so，以及 call_rust_cxx、call_rust_static
Makefile             先编两个库，再 cargo rustc，再进入 c/ 和 cxx/ 链接 rust_lib
static_link/         静态链接 libfoo.a
dylib_link/          动态链接 libfoo.so
static_link_cxx/     静态链接 libbar.a，并加上 -lstdc++
dylib_link_cxx/      动态链接 libbar.so
rust_lib/             cargo 编出 librust_lib.a 和 librust_lib.so，导出 rust_scale
c/call_rust.c        C 程序，分别静态、动态链接 librust_lib
cxx/call_rust.cpp    C++ 程序，分别静态、动态链接 librust_lib
scripts/build.sh     在仓库根目录执行 make
scripts/run.sh       设置 LD_LIBRARY_PATH 后运行八个程序
```

`#[link]` 告诉 rustc 链哪一个库、用静态还是共享。库不在系统路径里，搜索路径由 `cargo rustc -- -L` 传入。

```text
cargo rustc -p static_link -- -L native=$(CURDIR)/c/build
cargo rustc -p dylib_link -- -L native=$(CURDIR)/c/build
cargo rustc -p static_link_cxx -- -L native=$(CURDIR)/cxx/build -C link-arg=-lstdc++
cargo rustc -p dylib_link_cxx -- -L native=$(CURDIR)/cxx/build
```

`--` 后面的参数只传给这个包的 rustc。这里的 `-L` 和 `-C` 都是 rustc 的参数。

`-L native=目录` 给链接器增加一条系统库搜索路径。`native` 表示找 `libfoo.a`、`libfoo.so` 这种 C/C++ 库，不是 Rust 的 rlib。它只回答「到哪去找」。链哪一个库、静态还是共享，仍由 `#[link]` 决定。所以 `-L native=$(CURDIR)/c/build` 让 `#[link(name = "foo")]` 能找到 `c/build/libfoo.a` 或 `libfoo.so`。

`-C` 是 rustc 的 codegen 选项开关，形式是 `-C 选项` 或 `-C 选项=值`。它本身不是交给 ld 的标志。这里用的选项是 `link-arg`：`-C link-arg=-lstdc++` 把字符串 `-lstdc++` 追加到最终链接命令的末尾，因此它排在 `libbar.a` 后面，链接器才能用 `libstdc++` 补上静态库里还没解析的 C++ 符号。

同一份 Makefile 里还有 Make 自己的 `-C`：`$(MAKE) -C c` 是「进入 `c/` 再执行 make」。这和 rustc 的 `-C` 不是同一个参数。

## C++ 和 C 的边界

Rust 调用 `testcall_cxx` 的写法和调用 `testcall` 相同：`extern "C"` 加上 `#[link]`。稳定的部分是平台的 C ABI。C++ 类 `PassedValue`、`std::string` 和异常都留在 `cxx/bar.cpp` 里。`extern "C"` 让导出的符号名就是 `testcall_cxx`，不做 C++ 名字改写。异常在这个函数里接住，不传给 Rust。

`libbar.a` 是目标文件的归档，不会记下对 `libstdc++` 的依赖，所以静态链接要在命令末尾加 `-lstdc++`。`libbar.so` 由 `g++ -shared` 生成，自己已经依赖 `libstdc++.so`。

## 结构体和指针

`c/scale.h` 里的 `ScaleArgs` 有两个字段：`float value` 和 `int times`。Rust 用 `#[repr(C)]` 按同样的顺序摆放，类型写成 `f32` 和 `i32`。Linux 的 LP64 上 `int` 是 32 位。

`testcall_scale` 和 `testcall_scale_cxx` 接收 `const ScaleArgs *` 与 `float *`。Rust 把 `&args`、`&mut product` 传进去，库把 `value * times` 写回这块 `float`。任一指针为空时函数返回 `-1`，不写结果。C++ 类仍然留在 `bar.cpp` 里面。

## C 和 C++ 调用 Rust 库

`rust_lib` 的 `crate-type` 是 `staticlib` 和 `cdylib`。`cargo build -p rust_lib` 得到 `target/debug/librust_lib.a` 和 `librust_lib.so`。导出函数是 `#[no_mangle] pub extern "C" fn rust_scale`，符号名就是 `rust_scale`。

C 程序 [`c/call_rust.c`](c/call_rust.c) 和 C++ 程序 [`cxx/call_rust.cpp`](cxx/call_rust.cpp) 都声明这个函数，并把 `ScaleArgs` 的指针传进去。链接步骤在 `c/Makefile` 和 `cxx/Makefile` 的 `call_rust` 目标里，不放进这两个目录的 `all`，所以编 `libfoo`、`libbar` 时还不会去找 Rust 库。根目录先编出 Rust 库，再把 `target/debug` 的绝对路径传进子目录：

```text
cargo build -p rust_lib
$(MAKE) -C c call_rust RUST_LIB_DIR=$(CURDIR)/target/debug
$(MAKE) -C cxx call_rust RUST_LIB_DIR=$(CURDIR)/target/debug
```

在容器里 `$(CURDIR)` 是 `/src`，所以传下去的路径是 `/src/target/debug`。动态链接写 `-L target/debug -l:librust_lib.so`，可执行文件里只记下 `librust_lib.so` 这个名字。静态链接把 `librust_lib.a` 的路径写进命令。运行动态链接的那两个程序时，`scripts/run.sh` 把 `target/debug` 放进 `LD_LIBRARY_PATH`。

## 接口标准

Rust 和这两个库之间的约定是目标平台的 C ABI。库文件本身是 ELF。

- x86_64 上参数、返回值和栈的摆放：[System V AMD64 ABI](https://gitlab.com/x86-psABIs/x86-64-ABI)。该页给出当前 PDF。`f32` 与 C 的 `float` 按这份文档传递。
- arm64 上同一件事：[Procedure Call Standard for the Arm 64-bit Architecture（AAPCS64）](https://github.com/ARM-software/abi-aa/blob/main/aapcs64/aapcs64.rst)。
- `.o`、`.so` 和动态链接段：[System V ELF gABI](https://www.sco.com/developers/gabi/latest/contents.html)。共享库依赖写在 [Dynamic Section](https://www.sco.com/developers/gabi/latest/ch5.dynamic.html)。
- `extern "C"` 是 C++ 的语言链接，符号名保持 `testcall_cxx`：[C++ 工作草案 dcl.link](https://eel.is/c++draft/dcl.link)。条目说明见 [cppreference: Language linkage](https://en.cppreference.com/w/cpp/language/language_linkage)。
- 没有 `extern "C"` 时，`PassedValue` 的符号会按 [Itanium C++ ABI](https://itanium-cxx-abi.github.io/cxx-abi/abi.html) 改写。Linux 上的 `libstdc++` 也按这份 ABI 实现。Rust 不按它调用类和异常。
- Rust 的 `extern "C"` 块和 `#[link]`：[The Rust Reference: External blocks](https://doc.rust-lang.org/reference/items/external-blocks.html)、[`link` 属性](https://doc.rust-lang.org/reference/items/external-blocks.html#the-link-attribute)。`f32` 使用 [C representation](https://doc.rust-lang.org/reference/type-layout.html#the-c-representation)。调用外部分函数的约定写在 [The Rustonomicon: FFI](https://doc.rust-lang.org/nomicon/ffi.html)。

本项目把上述标准接进链接器的地方：

- [`cargo rustc`](https://doc.rust-lang.org/cargo/commands/cargo-rustc.html)：`--` 之后的参数只传给该包的 rustc。
- [`-L`](https://doc.rust-lang.org/rustc/command-line-arguments.html#option-l-search-path) 增加库搜索路径。`native` 只搜索系统库。[`-l`](https://doc.rust-lang.org/rustc/command-line-arguments.html#option-l-link-lib) 才指定库名和 `static` / `dylib`。
- [`-C`](https://doc.rust-lang.org/rustc/codegen-options/index.html) 选择 rustc 的 codegen 选项。[`link-arg`](https://doc.rust-lang.org/rustc/codegen-options/index.html#link-arg) 把后面的字符串原样追加给链接器。
- [`g++ -shared`](https://gcc.gnu.org/onlinedocs/gcc/Link-Options.html) 生成 `libbar.so` 并记下它对 `libstdc++.so` 的依赖。
- 运行时用 `LD_LIBRARY_PATH` 找到 `libfoo.so` 和 `libbar.so`，规则在 [ld.so(8)](https://man7.org/linux/man-pages/man8/ld.so.8.html)。

先做出镜像。CPU 由 `--platform` 决定，镜像里的脚本相同。

```bash
docker build --platform linux/arm64 -t rust-and-cmake:arm64 .
docker build --platform linux/amd64 -t rust-and-cmake:amd64 .
```

镜像构建时会自动跑一遍 `scripts/build.sh` 和 `scripts/run.sh`。不进容器、只看运行结果：

```bash
docker run --rm rust-and-cmake:arm64
```

要自己在容器里再走一遍构建，用 `bash` 盖掉默认命令。工作目录是 `/src`。

```bash
docker run --rm -it rust-and-cmake:arm64 bash
```

容器里：

```bash
make clean
./scripts/build.sh
./scripts/run.sh
```

amd64 镜像同样进入，把标签换成 `rust-and-cmake:amd64`。

## 构建之后文件在哪

路径都相对容器里的 `/src`。

```text
c/build/foo.o                    gcc -c 得到的目标文件
c/build/libfoo.a                 C 静态库
c/build/libfoo.so                C 共享库
cxx/build/bar.o                  g++ -c 得到的目标文件
cxx/build/libbar.a               C++ 静态库
cxx/build/libbar.so              C++ 共享库

target/debug/static_link         静态链接了 libfoo.a
target/debug/dylib_link          动态链接 libfoo.so
target/debug/static_link_cxx     静态链接了 libbar.a
target/debug/dylib_link_cxx      动态链接 libbar.so
target/debug/librust_lib.a      Rust 静态库，符号 rust_scale
target/debug/librust_lib.so     Rust 共享库，符号 rust_scale
c/build/call_rust               C 动态链接 librust_lib.so
c/build/call_rust_static        C 静态链接 librust_lib.a
cxx/build/call_rust_cxx         C++ 动态链接 librust_lib.so
cxx/build/call_rust_static      C++ 静态链接 librust_lib.a
target/debug/*.d                 rustc 的文本依赖清单，不是动态库
target/debug/incremental/        rustc 增量编译缓存
target/debug/examples/           Cargo 建的空目录。这个项目没有 example
```

`.d` 里写着对应的可执行文件依赖哪份 `main.rs`。Linux 动态库是 `c/build/libfoo.so` 和 `cxx/build/libbar.so`。

## CI

[.github/workflows/build.yml](.github/workflows/build.yml) 在 `ubuntu-24.04` 和 `ubuntu-24.04-arm` 上各跑一次 `docker build`。镜像构建过程会执行 `scripts/build.sh` 和 `scripts/run.sh`，任一步失败则这次 CI 失败。
