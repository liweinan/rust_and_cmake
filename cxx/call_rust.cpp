#include <stdio.h>
#include <string>

#include "../c/scale.h"

// extern "C" 按 C ABI 声明 Rust 导出的函数。C++ 名字改写不会加到 rust_scale 上。
extern "C" int rust_scale(const ScaleArgs *args, float *out);

int main() {
    ScaleArgs args = {3.14159f, 2};
    float product = 0.0f;
    int status = rust_scale(&args, &product);
    std::string prefix("C++ called Rust: ");
    printf("%sstatus %d, product %f\n", prefix.c_str(), status, product);
    fflush(stdout);

    int null_status = rust_scale(nullptr, &product);
    printf("C++ called Rust null: %d\n", null_status);
    fflush(stdout);

    if (status != 0 || product < 6.2f || product > 6.3f || null_status != -1) {
        return 1;
    }
    return 0;
}
