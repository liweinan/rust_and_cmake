// #[link] 是属性，写在紧跟着的 extern 块上。它会让 rustc 加上 -l static=foo。
// name = "foo" 对应库文件名 libfoo.a：Linux 静态库是 lib + 名字 + .a。
// kind = "static" 表示链接期把库收进可执行文件，运行时不再打开 libfoo.so。
// 库不在系统目录里。根目录 Makefile 用 cargo rustc -- -L native=.../c/build
// 把搜索路径传给 rustc。项目里没有 build.rs。
#[link(name = "foo", kind = "static")]
// extern "C" 用 C 的调用约定声明函数，不生成 Rust 名字修饰。
// 块里只有声明。函数体在 c/foo.c。
extern "C" {
    fn testcall(v: f32);
    // 参数是指针。返回值是 ScaleResult 本身，空指针时 status 为 -1。
    fn testcall_scale(args: *const ScaleArgs) -> ScaleResult;
    // malloc 得到的 ScaleResult。空参数返回空指针。调用方用 free 释放。
    fn testcall_scale_alloc(args: *const ScaleArgs) -> *mut ScaleResult;
}

// free 在 libc，不在 libfoo 里。
extern "C" {
    fn free(ptr: *mut std::ffi::c_void);
}

// #[repr(C)] 按 C ABI 摆放字段，和 c/scale.h 里的 ScaleArgs 相同。
// value 对 float，times 对 int。Linux LP64 上 int 是 32 位，所以用 i32。
// 两个字段都是 4 字节，结构体里没有补齐。
#[repr(C)]
struct ScaleArgs {
    value: f32,
    times: i32,
}

// status 对 int，product 对 float。和 c/scale.h 的 ScaleResult 相同。
#[repr(C)]
struct ScaleResult {
    status: i32,
    product: f32,
}

fn main() {
    // println! 是宏。编译期展开成往标准输出写格式化文本的代码。
    println!("Hello, world from Rust! (static)");
    // extern 块里的函数调用必须放在 unsafe 里：rustc 不检查 C 侧有没有越界、
    // 空指针或错误的参数类型。
    unsafe {
        testcall(3.14159);
    }

    let args = ScaleArgs {
        value: 3.14159,
        times: 2,
    };
    // &args 变成 *const ScaleArgs。返回的 ScaleResult 按 C ABI 放进寄存器。
    let result = unsafe { testcall_scale(&args) };
    println!("scale status: {}, product: {:.6}", result.status, result.product);

    let null_result = unsafe { testcall_scale(std::ptr::null()) };
    println!("null args status: {}", null_result.status);

    let allocated = unsafe { testcall_scale_alloc(&args) };
    if allocated.is_null() {
        println!("alloc status: null");
        std::process::exit(1);
    }
    let status = unsafe { (*allocated).status };
    let product = unsafe { (*allocated).product };
    println!("alloc status: {status}, product: {product:.6}");
    unsafe { free(allocated.cast()) };

    let null_allocated = unsafe { testcall_scale_alloc(std::ptr::null()) };
    if null_allocated.is_null() {
        println!("null alloc: null");
    } else {
        unsafe { free(null_allocated.cast()) };
        println!("null alloc: non-null");
        std::process::exit(1);
    }
}
