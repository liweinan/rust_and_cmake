// #[link] 是属性，写在紧跟着的 extern 块上。
// name = "foo" 对应库文件名 libfoo.a：Linux 静态库是 lib + 名字 + .a。
// kind = "static" 表示链接期把库收进可执行文件，运行时不再打开 libfoo.so。
// 到哪个目录找这个库，由 build.rs 的 cargo:rustc-link-search 决定，这里是 ../c/build。
#[link(name = "foo", kind = "static")]
// extern "C" 用 C 的调用约定声明函数，不生成 Rust 名字修饰。
// 块里只有声明。函数体在 c/foo.c 的 testcall，参数 float 对应 Rust 的 f32。
extern "C" {
    fn testcall(v: f32);
}

fn main() {
    // println! 是宏。编译期展开成往标准输出写格式化文本的代码。
    println!("Hello, world from Rust! (static)");
    // extern 块里的函数调用必须放在 unsafe 里：rustc 不检查 C 侧有没有越界、
    // 空指针或错误的参数类型。这里参数是一个普通的 f32，和 C 的 float 一致。
    unsafe {
        testcall(3.14159);
    }
}
