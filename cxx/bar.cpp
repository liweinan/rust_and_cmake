#include <exception>
#include <memory>
#include <stdio.h>
#include <string>

#include "../c/scale.h"

// PassedValue 只存在于这个 C++ 库里。Rust 不声明这个类。
class PassedValue {
public:
    explicit PassedValue(float value) : value_(value) {
        label_ = "Hello, world from C++! Value passed: ";
    }

    void print() const {
        printf("%s%f\n", label_.c_str(), value_);
        fflush(stdout);
    }

private:
    std::string label_;
    float value_;
};

// extern "C" 使用 C 的调用约定，符号名保持 testcall_cxx，不做 C++ 名字改写。
// 这是 Rust 能稳定调用的边界。类、std::string、异常都留在边界里面。
extern "C" void testcall_cxx(float value) {
    try {
        PassedValue passed(value);
        passed.print();
    } catch (const std::exception& error) {
        printf("C++ exception: %s\n", error.what());
    } catch (...) {
        printf("C++ exception\n");
    }
}

// ScaleArgs 和 ScaleResult 来自 c/scale.h，布局和 Rust 的 #[repr(C)] 一致。
// 返回值是 ScaleResult 本身。空指针时 status 为 -1。不把 C++ 对象交出去。
extern "C" ScaleResult testcall_scale_cxx(const ScaleArgs *args) {
    ScaleResult result{-1, 0.0f};
    if (args == nullptr) {
        return result;
    }
    try {
        std::string label("Hello, world from C++! ");
        result.status = 0;
        result.product = args->value * static_cast<float>(args->times);
        printf("%s%f x %d = %f\n", label.c_str(), args->value, args->times, result.product);
        fflush(stdout);
        return result;
    } catch (const std::exception& error) {
        printf("C++ exception: %s\n", error.what());
        result.status = -1;
        result.product = 0.0f;
        return result;
    } catch (...) {
        printf("C++ exception\n");
        result.status = -1;
        result.product = 0.0f;
        return result;
    }
}

// unique_ptr 在离开作用域时 delete。release 把裸指针交出去，调用方用 testcall_scale_free_cxx 收回。
// 空参数或异常返回空指针。异常发生在 release 之前时，unique_ptr 自己 delete。
extern "C" ScaleResult *testcall_scale_alloc_cxx(const ScaleArgs *args) {
    if (args == nullptr) {
        return nullptr;
    }
    try {
        auto owned = std::make_unique<ScaleResult>();
        std::string label("Hello, world from C++ alloc! ");
        owned->status = 0;
        owned->product = args->value * static_cast<float>(args->times);
        printf("%s%f x %d = %f\n", label.c_str(), args->value, args->times, owned->product);
        fflush(stdout);
        return owned.release();
    } catch (const std::exception& error) {
        printf("C++ exception: %s\n", error.what());
        return nullptr;
    } catch (...) {
        printf("C++ exception\n");
        return nullptr;
    }
}

// delete 空指针是空操作。有析构函数的对象必须走这里，不能用 free。
extern "C" void testcall_scale_free_cxx(ScaleResult *result) {
    delete result;
}
