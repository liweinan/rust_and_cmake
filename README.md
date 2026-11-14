Rust 链接同一份 C 库：静态库和共享库。构建在 Linux 容器里完成，脚本不区分 x86 和 arm。没有 `build.rs`。

```text
c/foo.c              C 函数 testcall
c/Makefile           编出 libfoo.a 和 libfoo.so
Makefile             先调用 c/Makefile，再 cargo rustc，用 -L 指出库目录
static_link/         #[link(kind = "static")]，链接 libfoo.a
dylib_link/          #[link(kind = "dylib")]，链接 libfoo.so
scripts/build.sh     在仓库根目录执行 make
scripts/run.sh       设置 LD_LIBRARY_PATH 后运行两个程序
```

`#[link]` 告诉 rustc 链 `libfoo.a` 还是 `libfoo.so`。库在 `c/build`，不在系统路径里，所以 Makefile 里是：

```text
cargo rustc -p static_link -- -L native=$(CURDIR)/c/build
cargo rustc -p dylib_link -- -L native=$(CURDIR)/c/build
```

`--` 后面的参数只传给这个包的 rustc。`-L native=...` 相当于链接器的库搜索路径。

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

`scripts/build.sh` 执行根目录的 `make`：`c/Makefile` 得到 `c/build/libfoo.a` 和 `c/build/libfoo.so`，然后两次 `cargo rustc`。`scripts/run.sh` 把 `c/build` 放进 `LD_LIBRARY_PATH`，再运行 `target/debug/static_link` 和 `target/debug/dylib_link`。

amd64 镜像同样进入，把标签换成 `rust-and-cmake:amd64`。

## 构建之后文件在哪

路径都相对容器里的 `/src`。`make -C c` 的产物在 `c/build`，`cargo rustc` 的产物在 `target/debug`。

```text
c/build/foo.o                 gcc -c 得到的目标文件
c/build/libfoo.a              静态库。static_link 链接时被打进可执行文件
c/build/libfoo.so             共享库。dylib_link 运行时按 LD_LIBRARY_PATH 加载

target/debug/static_link      可执行文件，静态链接了 libfoo.a
target/debug/dylib_link       可执行文件，动态链接 libfoo.so
target/debug/static_link.d    文本依赖清单，不是动态库
target/debug/dylib_link.d     同上，对应 dylib_link
target/debug/incremental/     rustc 增量编译缓存
target/debug/examples/        Cargo 建的目录。这个项目没有 example，所以是空的
```

`.d` 是 rustc 写给 Cargo 的依赖列表，格式和 make 的依赖文件一样。例如 `target/debug/dylib_link.d` 里写着这个可执行文件依赖 `dylib_link/src/main.rs`。Linux 动态库是 `c/build/libfoo.so`，不在 `target/debug` 里。

## CI

[.github/workflows/build.yml](.github/workflows/build.yml) 在 `ubuntu-24.04` 和 `ubuntu-24.04-arm` 上各跑一次 `docker build`。镜像构建过程会执行 `scripts/build.sh` 和 `scripts/run.sh`，任一步失败则这次 CI 失败。
