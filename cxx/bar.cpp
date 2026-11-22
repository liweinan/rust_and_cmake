#include <cstdlib>
#include <exception>
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

// 用 malloc 分配 ScaleResult，返回指针。调用方用 free 释放，不要用 delete。
// 空参数、分配失败或异常都返回空指针。异常路径会先 free，避免漏掉这块堆内存。
extern "C" ScaleResult *testcall_scale_alloc_cxx(const ScaleArgs *args) {
    if (args == nullptr) {
        return nullptr;
    }
    auto *result = static_cast<ScaleResult *>(std::malloc(sizeof(ScaleResult)));
    if (result == nullptr) {
        return nullptr;
    }
    try {
        std::string label("Hello, world from C++ alloc! ");
        result->status = 0;
        result->product = args->value * static_cast<float>(args->times);
        printf("%s%f x %d = %f\n", label.c_str(), args->value, args->times, result->product);
        fflush(stdout);
        return result;
    } catch (const std::exception& error) {
        printf("C++ exception: %s\n", error.what());
        std::free(result);
        return nullptr;
    } catch (...) {
        printf("C++ exception\n");
        std::free(result);
        return nullptr;
    }
}
