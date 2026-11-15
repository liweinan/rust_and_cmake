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

// ScaleArgs 来自 c/scale.h，布局和 Rust 的 #[repr(C)] 结构体一致。
// 空指针返回 -1。乘法结果写入调用方的 float，不把 C++ 对象交出去。
extern "C" int testcall_scale_cxx(const ScaleArgs *args, float *out) {
    if (args == nullptr || out == nullptr) {
        return -1;
    }
    try {
        std::string label("Hello, world from C++! ");
        *out = args->value * static_cast<float>(args->times);
        printf("%s%f x %d = %f\n", label.c_str(), args->value, args->times, *out);
        fflush(stdout);
        return 0;
    } catch (const std::exception& error) {
        printf("C++ exception: %s\n", error.what());
        return -1;
    } catch (...) {
        printf("C++ exception\n");
        return -1;
    }
}
