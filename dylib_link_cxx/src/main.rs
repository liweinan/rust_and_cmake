// #[link] 是属性，写在紧跟着的 extern 块上。它会让 rustc 加上 -l dylib=bar。
// name = "bar" 对应 cxx/build/libbar.so。kind = "dylib" 表示运行时打开这个共享库。
// 根目录 Makefile 用 -L native=.../cxx/build 指出这个目录。
// libbar.so 由 g++ -shared 生成，已经依赖 libstdc++.so，这里不用再写 -lstdc++。
// 运行时把 cxx/build 放进 LD_LIBRARY_PATH，见 scripts/run.sh。
#[link(name = "bar", kind = "dylib")]
// extern "C" 按 C ABI 声明 testcall_cxx。C++ 类 PassedValue 不出现在这里。
// 参数 float 对应 Rust 的 f32。函数体在 cxx/bar.cpp。
extern "C" {
    fn testcall_cxx(v: f32);
}

fn main() {
    // println! 是宏。编译期展开成往标准输出写格式化文本的代码。
    println!("Hello, world from Rust! (dylib c++)");
    // 调用 extern 块里的函数要放在 unsafe 里。C++ 异常已在 testcall_cxx 内部接住。
    unsafe {
        testcall_cxx(3.14159);
    }
}
