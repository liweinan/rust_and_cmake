#include <stdio.h>
#include <string>

#include "../c/scale.h"

// extern "C" 按 C ABI 声明 Rust 导出的函数。C++ 名字改写不会加到 rust_scale 上。
extern "C" ScaleResult rust_scale(const ScaleArgs *args);
extern "C" ScaleResult *rust_scale_alloc(const ScaleArgs *args);
extern "C" void rust_scale_free(ScaleResult *result);

int main() {
    ScaleArgs args = {3.14159f, 2};
    ScaleResult result = rust_scale(&args);
    std::string prefix("C++ called Rust: ");
    printf("%sstatus %d, product %f\n", prefix.c_str(), result.status, result.product);
    fflush(stdout);

    ScaleResult null_result = rust_scale(nullptr);
    printf("C++ called Rust null: %d\n", null_result.status);
    fflush(stdout);

    ScaleResult *allocated = rust_scale_alloc(&args);
    int alloc_status = allocated == nullptr ? -1 : allocated->status;
    float alloc_product = allocated == nullptr ? 0.0f : allocated->product;
    std::string alloc_prefix("C++ called Rust alloc: ");
    printf("%sstatus %d, product %f\n", alloc_prefix.c_str(), alloc_status, alloc_product);
    fflush(stdout);
    rust_scale_free(allocated);

    ScaleResult *null_allocated = rust_scale_alloc(nullptr);
    printf("C++ called Rust alloc null: %s\n", null_allocated == nullptr ? "null" : "non-null");
    fflush(stdout);
    rust_scale_free(null_allocated);

    if (result.status != 0 || result.product < 6.2f || result.product > 6.3f || null_result.status != -1) {
        return 1;
    }
    if (alloc_status != 0 || alloc_product < 6.2f || alloc_product > 6.3f || null_allocated != nullptr) {
        return 1;
    }
    return 0;
}
