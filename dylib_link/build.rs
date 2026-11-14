use std::path::PathBuf;

fn main() {
    // env! 是编译期宏，在编译 build.rs 时展开，不是运行时读环境变量。
    // CARGO_MANIFEST_DIR 由 Cargo 注入，值是本 crate 的目录。
    // 容器里是 /src/dylib_link，拼上 ../c/build 得到 /src/c/build。
    // 这个展开会记进 target/debug/build/.../build_script_build.d 的 env-dep 行。
    let lib_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../c/build");

    // println! 是宏。以 cargo: 开头的行由 Cargo 读取，不会进最终程序的标准输出。
    // rustc-link-search=native=目录 相当于链接器的 -L。native 表示本机库，不是 Rust 的 rlib。
    println!("cargo:rustc-link-search=native={}", lib_dir.display());
    // rustc-link-lib=dylib=foo 相当于 -lfoo，并指定共享库，即 c/build/libfoo.so。
    // 链接期只把库名写进可执行文件；运行时由 scripts/run.sh 用 LD_LIBRARY_PATH 找到它。
    // main.rs 里的 #[link(name = "foo", kind = "dylib")] 声明的是同一个库。
    println!("cargo:rustc-link-lib=dylib=foo");

    // rerun-if-changed 把路径登记成这个包的重建条件。
    // Cargo 会把它们写进 target/debug/dylib_link.d。那个 .d 是文本依赖清单，
    // 格式类似 make，不是 Linux 的 .so。共享库在 c/build/libfoo.so。
    println!("cargo:rerun-if-changed=../c/foo.c");
    println!("cargo:rerun-if-changed=../c/Makefile");
}
