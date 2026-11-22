#include <stdio.h>

#include "scale.h"

/* rust_scale 的函数体在 rust_lib。这里只有 C ABI 的声明。 */
ScaleResult rust_scale(const ScaleArgs *args);
ScaleResult *rust_scale_alloc(const ScaleArgs *args);
void rust_scale_free(ScaleResult *result);

int main(void) {
    ScaleArgs args = {.value = 3.14159f, .times = 2};
    ScaleResult result = rust_scale(&args);
    printf("C called Rust: status %d, product %f\n", result.status, result.product);
    fflush(stdout);

    ScaleResult null_result = rust_scale(NULL);
    printf("C called Rust null: %d\n", null_result.status);
    fflush(stdout);

    ScaleResult *allocated = rust_scale_alloc(&args);
    int alloc_status = allocated == NULL ? -1 : allocated->status;
    float alloc_product = allocated == NULL ? 0.0f : allocated->product;
    printf("C called Rust alloc: status %d, product %f\n", alloc_status, alloc_product);
    fflush(stdout);
    rust_scale_free(allocated);

    ScaleResult *null_allocated = rust_scale_alloc(NULL);
    printf("C called Rust alloc null: %s\n", null_allocated == NULL ? "null" : "non-null");
    fflush(stdout);
    rust_scale_free(null_allocated);

    if (result.status != 0 || result.product < 6.2f || result.product > 6.3f || null_result.status != -1) {
        return 1;
    }
    if (alloc_status != 0 || alloc_product < 6.2f || alloc_product > 6.3f || null_allocated != NULL) {
        return 1;
    }
    return 0;
}
