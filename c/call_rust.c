#include <stdio.h>

#include "scale.h"

/* rust_scale 的函数体在 rust_lib。这里只有 C ABI 的声明。 */
int rust_scale(const ScaleArgs *args, float *out);

int main(void) {
    ScaleArgs args = {.value = 3.14159f, .times = 2};
    float product = 0.0f;
    int status = rust_scale(&args, &product);
    printf("C called Rust: status %d, product %f\n", status, product);
    fflush(stdout);

    int null_status = rust_scale(NULL, &product);
    printf("C called Rust null: %d\n", null_status);
    fflush(stdout);

    if (status != 0 || product < 6.2f || product > 6.3f || null_status != -1) {
        return 1;
    }
    return 0;
}
