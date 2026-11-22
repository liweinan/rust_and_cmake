/* ScaleArgs 是跨 Rust / C / C++ 的普通数据。
 * float 和 int 在 Linux LP64 上都是 4 字节，对齐也是 4，中间没有补齐字节。
 */
#ifndef SCALE_ARGS_H
#define SCALE_ARGS_H

typedef struct ScaleArgs {
    float value;
    int times;
} ScaleArgs;

/* 返回这个结构体本身。status 和 product 各 4 字节，一共 8 字节，中间没有补齐。
 * 不返回指向局部变量的指针：函数返回后那块栈就不能再读。
 */
typedef struct ScaleResult {
    int status;
    float product;
} ScaleResult;

#endif
