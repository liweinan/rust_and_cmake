#include <stdio.h>
#include <stdlib.h>

#include "scale.h"

void testcall(float value) {
    printf("Hello, world from C! Value passed: %f\n", value);
    /* 接到管道时 stdout 是全缓冲。fflush 让这行马上出现，顺序和调用一致。 */
    fflush(stdout);
}

/* 参数是指针。空指针时 status 为 -1，product 保持 0。
 * 返回值是 ScaleResult 这个结构体，不是指向它的指针。
 */
ScaleResult testcall_scale(const ScaleArgs *args) {
    ScaleResult result = {.status = -1, .product = 0.0f};
    if (args == NULL) {
        return result;
    }
    result.status = 0;
    result.product = args->value * (float)args->times;
    printf("Hello, world from C! %f x %d = %f\n", args->value, args->times, result.product);
    fflush(stdout);
    return result;
}

/* malloc 一块 ScaleResult，返回这块堆内存的指针。
 * 空参数或 malloc 失败返回 NULL。调用方用 free 释放。
 * 不能返回局部变量的地址，函数返回后那块栈已经无效。
 */
ScaleResult *testcall_scale_alloc(const ScaleArgs *args) {
    ScaleResult *result;
    if (args == NULL) {
        return NULL;
    }
    result = malloc(sizeof(*result));
    if (result == NULL) {
        return NULL;
    }
    result->status = 0;
    result->product = args->value * (float)args->times;
    printf("Hello, world from C alloc! %f x %d = %f\n", args->value, args->times, result->product);
    fflush(stdout);
    return result;
}
