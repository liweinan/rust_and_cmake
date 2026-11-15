#include <stdio.h>

#include "scale.h"

void testcall(float value) {
    printf("Hello, world from C! Value passed: %f\n", value);
    /* 接到管道时 stdout 是全缓冲。fflush 让这行马上出现，顺序和调用一致。 */
    fflush(stdout);
}

/* args、out 都是指针。任一为空就返回 -1，不去写 out。 */
int testcall_scale(const ScaleArgs *args, float *out) {
    if (args == NULL || out == NULL) {
        return -1;
    }
    *out = args->value * (float)args->times;
    printf("Hello, world from C! %f x %d = %f\n", args->value, args->times, *out);
    fflush(stdout);
    return 0;
}
