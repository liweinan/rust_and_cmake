#include <exception>
#include <stdio.h>
#include <string>

// PassedValue 只存在于这个 C++ 库里。Rust 不声明这个类。
class PassedValue {
public:
    explicit PassedValue(float value) : value_(value) {
        label_ = "Hello, world from C++! Value passed: ";
    }

    void print() const {
        printf("%s%f\n", label_.c_str(), value_);
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
