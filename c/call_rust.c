#include <stdio.h>

#include "scale.h"

/* rust_scale 的函数体在 rust_lib。这里只有 C ABI 的声明。 */
ScaleResult rust_scale(const ScaleArgs *args);

int main(void) {
    ScaleArgs args = {.value = 3.14159f, .times = 2};
    ScaleResult result = rust_scale(&args);
    printf("C called Rust: status %d, product %f\n", result.status, result.product);
    fflush(stdout);

    ScaleResult null_result = rust_scale(NULL);
    printf("C called Rust null: %d\n", null_result.status);
    fflush(stdout);

    if (result.status != 0 || result.product < 6.2f || result.product > 6.3f || null_result.status != -1) {
        return 1;
    }
    return 0;
}
