// #[link] 是属性，写在紧跟着的 extern 块上。它会让 rustc 加上 -l static=bar。
// name = "bar" 对应 cxx/build/libbar.a。kind = "static" 表示链接期收进可执行文件。
// 根目录 Makefile 用 -L native=.../cxx/build 指出这个目录，
// 并用 -C link-arg=-lstdc++ 在链接命令末尾加上 C++ 标准库。
// libbar.a 里的 std::string 需要 libstdc++；静态归档自己不会带上这个依赖。
#[link(name = "bar", kind = "static")]
// extern "C" 按 C ABI 声明函数。C++ 类 PassedValue 不出现在这里。
// 函数体在 cxx/bar.cpp。ScaleArgs 的布局在 c/scale.h。
extern "C" {
    fn testcall_cxx(v: f32);
    fn testcall_scale_cxx(args: *const ScaleArgs) -> ScaleResult;
    fn testcall_scale_alloc_cxx(args: *const ScaleArgs) -> *mut ScaleResult;
}

extern "C" {
    fn free(ptr: *mut std::ffi::c_void);
}

// #[repr(C)] 按 C ABI 摆放字段，和 c/scale.h 里的 ScaleArgs 相同。
// value 对 float，times 对 int。Linux LP64 上 int 是 32 位，所以用 i32。
#[repr(C)]
struct ScaleArgs {
    value: f32,
    times: i32,
}

#[repr(C)]
struct ScaleResult {
    status: i32,
    product: f32,
}

fn main() {
    // println! 是宏。编译期展开成往标准输出写格式化文本的代码。
    println!("Hello, world from Rust! (static c++)");
    // 调用 extern 块里的函数要放在 unsafe 里。C++ 异常已在库函数内部接住。
    unsafe {
        testcall_cxx(3.14159);
    }

    let args = ScaleArgs {
        value: 3.14159,
        times: 2,
    };
    let result = unsafe { testcall_scale_cxx(&args) };
    println!("scale status: {}, product: {:.6}", result.status, result.product);

    let null_result = unsafe { testcall_scale_cxx(std::ptr::null()) };
    println!("null args status: {}", null_result.status);

    let allocated = unsafe { testcall_scale_alloc_cxx(&args) };
    if allocated.is_null() {
        println!("alloc status: null");
        std::process::exit(1);
    }
    let status = unsafe { (*allocated).status };
    let product = unsafe { (*allocated).product };
    println!("alloc status: {status}, product: {product:.6}");
    unsafe { free(allocated.cast()) };

    let null_allocated = unsafe { testcall_scale_alloc_cxx(std::ptr::null()) };
    if null_allocated.is_null() {
        println!("null alloc: null");
    } else {
        unsafe { free(null_allocated.cast()) };
        println!("null alloc: non-null");
        std::process::exit(1);
    }
}
