// #[link] 是属性，写在紧跟着的 extern 块上。它会让 rustc 加上 -l static=bar。
// name = "bar" 对应 cxx/build/libbar.a。kind = "static" 表示链接期收进可执行文件。
// 根目录 Makefile 用 -L native=.../cxx/build 指出这个目录，
// 并用 -C link-arg=-lstdc++ 在链接命令末尾加上 C++ 标准库。
// libbar.a 里的 std::string 需要 libstdc++；静态归档自己不会带上这个依赖。
#[link(name = "bar", kind = "static")]
// extern "C" 按 C ABI 声明 testcall_cxx。C++ 类 PassedValue 不出现在这里。
// 参数 float 对应 Rust 的 f32。函数体在 cxx/bar.cpp。
extern "C" {
    fn testcall_cxx(v: f32);
}

fn main() {
    // println! 是宏。编译期展开成往标准输出写格式化文本的代码。
    println!("Hello, world from Rust! (static c++)");
    // 调用 extern 块里的函数要放在 unsafe 里。C++ 异常已在 testcall_cxx 内部接住。
    unsafe {
        testcall_cxx(3.14159);
    }
}
