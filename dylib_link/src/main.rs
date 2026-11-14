// #[link] 是属性，写在紧跟着的 extern 块上。
// name = "foo" 对应库文件名 libfoo.so：Linux 共享库是 lib + 名字 + .so。
// kind = "dylib" 表示可执行文件只记下库名，进程启动时由动态链接器打开 libfoo.so。
// 搜索路径仍由 build.rs 给出（../c/build）。运行时还要把该目录放进 LD_LIBRARY_PATH，
// 见 scripts/run.sh。静态链接的对照在 static_link，那边 kind 是 "static"。
#[link(name = "foo", kind = "dylib")]
// extern "C" 用 C 的调用约定声明函数，不生成 Rust 名字修饰。
// 块里只有声明。函数体在 c/foo.c 的 testcall，参数 float 对应 Rust 的 f32。
extern "C" {
    fn testcall(v: f32);
}

fn main() {
    // println! 是宏。编译期展开成往标准输出写格式化文本的代码。
    println!("Hello, world from Rust! (dylib)");
    // extern 块里的函数调用必须放在 unsafe 里：rustc 不检查 C 侧有没有越界、
    // 空指针或错误的参数类型。这里参数是一个普通的 f32，和 C 的 float 一致。
    unsafe {
        testcall(3.14159);
    }
}
