#include <stdio.h>
#include <string>

#include "../c/scale.h"

// extern "C" 按 C ABI 声明 Rust 导出的函数。C++ 名字改写不会加到 rust_scale 上。
extern "C" ScaleResult rust_scale(const ScaleArgs *args);

int main() {
    ScaleArgs args = {3.14159f, 2};
    ScaleResult result = rust_scale(&args);
    std::string prefix("C++ called Rust: ");
    printf("%sstatus %d, product %f\n", prefix.c_str(), result.status, result.product);
    fflush(stdout);

    ScaleResult null_result = rust_scale(nullptr);
    printf("C++ called Rust null: %d\n", null_result.status);
    fflush(stdout);

    if (result.status != 0 || result.product < 6.2f || result.product > 6.3f || null_result.status != -1) {
        return 1;
    }
    return 0;
}
