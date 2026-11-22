// #[repr(C)] 与 c/scale.h 的 ScaleArgs 字段顺序一致。
// value 对 float，times 对 int。Linux LP64 上 int 是 32 位。
#[repr(C)]
pub struct ScaleArgs {
    pub value: f32,
    pub times: i32,
}

// 与 c/scale.h 的 ScaleResult 字段顺序一致。一共 8 字节。
// 按值返回。空指针时 status 为 -1，product 为 0。
#[repr(C)]
pub struct ScaleResult {
    pub status: i32,
    pub product: f32,
}

// #[no_mangle] 让符号名保持 rust_scale，不使用 Rust 自己的改写。
// extern "C" 使用目标平台的 C ABI，C 和 C++ 都能按这个名字调用。
// 这个函数不能 panic 穿出边界。
#[no_mangle]
pub extern "C" fn rust_scale(args: *const ScaleArgs) -> ScaleResult {
    if args.is_null() {
        return ScaleResult {
            status: -1,
            product: 0.0,
        };
    }
    // *const 解引用要放在 unsafe 里。调用方保证指针指向 ScaleArgs。
    unsafe {
        let args = &*args;
        let product = args.value * args.times as f32;
        println!(
            "Hello, world from Rust lib! {:.6} x {} = {:.6}",
            args.value, args.times, product
        );
        ScaleResult {
            status: 0,
            product,
        }
    }
}

// Box::into_raw 把堆上的 ScaleResult 交出去，指针在函数返回后仍然有效。
// 空参数不分配，直接返回空指针。调用方必须用 rust_scale_free 释放，不能用 free。
#[no_mangle]
pub extern "C" fn rust_scale_alloc(args: *const ScaleArgs) -> *mut ScaleResult {
    if args.is_null() {
        return std::ptr::null_mut();
    }
    unsafe {
        let args = &*args;
        let product = args.value * args.times as f32;
        println!(
            "Hello, world from Rust lib alloc! {:.6} x {} = {:.6}",
            args.value, args.times, product
        );
        Box::into_raw(Box::new(ScaleResult {
            status: 0,
            product,
        }))
    }
}

// Box::from_raw 收回 rust_scale_alloc 交出去的指针。空指针直接返回。
#[no_mangle]
pub extern "C" fn rust_scale_free(result: *mut ScaleResult) {
    if result.is_null() {
        return;
    }
    unsafe {
        drop(Box::from_raw(result));
    }
}
