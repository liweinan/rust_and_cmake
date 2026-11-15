// #[link] 是属性，写在紧跟着的 extern 块上。它会让 rustc 加上 -l dylib=bar。
// name = "bar" 对应 cxx/build/libbar.so。kind = "dylib" 表示运行时打开这个共享库。
// 根目录 Makefile 用 -L native=.../cxx/build 指出这个目录。
// libbar.so 由 g++ -shared 生成，已经依赖 libstdc++.so，这里不用再写 -lstdc++。
// 运行时把 cxx/build 放进 LD_LIBRARY_PATH，见 scripts/run.sh。
#[link(name = "bar", kind = "dylib")]
// extern "C" 按 C ABI 声明函数。C++ 类 PassedValue 不出现在这里。
// 函数体在 cxx/bar.cpp。ScaleArgs 的布局在 c/scale.h。
extern "C" {
    fn testcall_cxx(v: f32);
    fn testcall_scale_cxx(args: *const ScaleArgs, out: *mut f32) -> i32;
}

// #[repr(C)] 按 C ABI 摆放字段，和 c/scale.h 里的 ScaleArgs 相同。
// value 对 float，times 对 int。Linux LP64 上 int 是 32 位，所以用 i32。
#[repr(C)]
struct ScaleArgs {
    value: f32,
    times: i32,
}

fn main() {
    // println! 是宏。编译期展开成往标准输出写格式化文本的代码。
    println!("Hello, world from Rust! (dylib c++)");
    // 调用 extern 块里的函数要放在 unsafe 里。C++ 异常已在库函数内部接住。
    unsafe {
        testcall_cxx(3.14159);
    }

    let args = ScaleArgs {
        value: 3.14159,
        times: 2,
    };
    let mut product = 0.0f32;
    let status = unsafe { testcall_scale_cxx(&args, &mut product) };
    println!("scale status: {status}, product: {product:.6}");

    let null_status = unsafe { testcall_scale_cxx(std::ptr::null(), &mut product) };
    println!("null args status: {null_status}");
}
