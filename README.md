Rust 链接同一份 C 库，以及一份用 C ABI 导出的 C++ 库。每种库都有静态链接和动态链接。构建在 Linux 容器里完成，脚本不区分 x86 和 arm。没有 `build.rs`。

```text
c/foo.c              C 函数 testcall
c/Makefile           编出 libfoo.a 和 libfoo.so
cxx/bar.cpp          C++ 类 PassedValue，用 extern "C" 导出 testcall_cxx
cxx/Makefile         编出 libbar.a 和 libbar.so
Makefile             先编两个库，再 cargo rustc
static_link/         静态链接 libfoo.a
dylib_link/          动态链接 libfoo.so
static_link_cxx/     静态链接 libbar.a，并加上 -lstdc++
dylib_link_cxx/      动态链接 libbar.so
scripts/build.sh     在仓库根目录执行 make
scripts/run.sh       设置 LD_LIBRARY_PATH 后运行四个程序
```

`#[link]` 告诉 rustc 链哪一个库、用静态还是共享。库不在系统路径里，搜索路径由 `cargo rustc -- -L` 传入。

```text
cargo rustc -p static_link -- -L native=$(CURDIR)/c/build
cargo rustc -p dylib_link -- -L native=$(CURDIR)/c/build
cargo rustc -p static_link_cxx -- -L native=$(CURDIR)/cxx/build -C link-arg=-lstdc++
cargo rustc -p dylib_link_cxx -- -L native=$(CURDIR)/cxx/build
```

`--` 后面的参数只传给这个包的 rustc。

## C++ 和 C 的边界

Rust 调用 `testcall_cxx` 的写法和调用 `testcall` 相同：`extern "C"` 加上 `#[link]`。稳定的部分是平台的 C ABI。C++ 类 `PassedValue`、`std::string` 和异常都留在 `cxx/bar.cpp` 里。`extern "C"` 让导出的符号名就是 `testcall_cxx`，不做 C++ 名字改写。异常在这个函数里接住，不传给 Rust。

`libbar.a` 是目标文件的归档，不会记下对 `libstdc++` 的依赖，所以静态链接要在命令末尾加 `-lstdc++`。`libbar.so` 由 `g++ -shared` 生成，自己已经依赖 `libstdc++.so`。

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
target/debug/*.d                 rustc 的文本依赖清单，不是动态库
target/debug/incremental/        rustc 增量编译缓存
target/debug/examples/           Cargo 建的空目录。这个项目没有 example
```

`.d` 里写着对应的可执行文件依赖哪份 `main.rs`。Linux 动态库是 `c/build/libfoo.so` 和 `cxx/build/libbar.so`。

## CI

[.github/workflows/build.yml](.github/workflows/build.yml) 在 `ubuntu-24.04` 和 `ubuntu-24.04-arm` 上各跑一次 `docker build`。镜像构建过程会执行 `scripts/build.sh` 和 `scripts/run.sh`，任一步失败则这次 CI 失败。
