#!/bin/sh
# 在容器的 bash 里查看 c/Makefile 编出的静态库和共享库。
# 先 make -C c，得到 c/build/libfoo.a 和 c/build/libfoo.so。
# 每条命令都可以单独复制到 bash 里执行。libbar 和 librust_lib 换路径即可。
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$ROOT"

make -C c

# 先打印将要执行的命令，再执行，最后用 note 解读刚才的输出。
run() {
    echo
    echo "$ $*"
    "$@"
}

note() {
    echo "解读：$*"
}

echo "== 静态库：ar 把 foo.o 打成归档，没有动态段 =="

# file 只看文件头，判断这是哪种文件，不列出符号。
# 静态库由 ar rcs 打包，文件头是归档魔数，所以类型是 ar archive，不是 ELF。
run file c/build/libfoo.a
note "current ar archive 表示这是 ar 归档。它本身不是 ELF，也不能直接执行。"

# ar t 列出归档里的成员名，对应 Makefile 的 ar rcs $@ build/foo.o。
# 这里只有 foo.o。链接器之后会从归档里抽出这个目标文件。
run ar t c/build/libfoo.a
note "成员只有 foo.o。静态库就是这个目标文件的打包，没有再做一次链接。"

# nm 列出目标文件的符号表。
# 地址为空、类型 U：此文件里用到了，但定义在别处，最终链接时才补上。
# 有地址、类型 T：定义在本文件的代码段，并且是全局符号，别的文件可以调用。
# fflush、malloc、printf、stdout 来自 libc，所以是 U。
# testcall、testcall_scale、testcall_scale_alloc 在 foo.c 里实现，所以是 T。
run nm c/build/libfoo.a
note "U 是未定义符号，要等链接 libc 时解析。T 是本文件导出的函数。"

# readelf -d 读取 ELF 的动态段（DT_NEEDED、DT_STRTAB、DT_SYMTAB 等）。
# foo.o 是可重定位目标文件，没有动态段。归档只是把它原样装进去。
# 因此这里打印 There is no dynamic section，而不是一份依赖清单。
echo
echo "$ readelf -d c/build/libfoo.a"
readelf -d c/build/libfoo.a || true
note "没有动态段。依赖 libc 这件事要到生成 .so 或最终可执行文件时才写进去。"

echo
echo "== 共享库：ELF 动态对象，动态段里有依赖和导出符号 =="

# file 对共享库会认出 ELF。LSB 是小端，shared object 是共享库，
# ARM aarch64 是这份容器的机器类型。dynamically linked 表示它还依赖别的 .so。
# not stripped 表示调试符号还在，nm 能看到函数名。
run file c/build/libfoo.so
note "这是 ELF 共享库。shared object 和 dynamically linked 说明它要在运行时再链接。"

# readelf -d 打印动态段，加载器按这里找依赖和符号表。
# NEEDED libc.so.6：运行时必须能找到 libc。
# STRTAB、SYMTAB：动态符号的名字表和符号表，加载器用它们解析 testcall 等名字。
# INIT、FINI、RELA、JMPREL 是初始化、收尾和重定位，本例不用逐项看。
run readelf -d c/build/libfoo.so
note "NEEDED 是运行时依赖，这里只有 libc.so.6。STRTAB 和 SYMTAB 是动态符号表。"

# nm -D 只看动态符号表，也就是别的程序能链接到的那些名字。
# --defined-only 去掉 U，只留下本库定义的符号。
# T 仍表示代码段里的全局函数。地址和 libfoo.a 里的不同：
# .so 已经链接过，地址是库内的偏移；.a 里的地址是 foo.o 自己的偏移。
run nm -D --defined-only c/build/libfoo.so
note "这三个 T 是共享库导出的函数。地址是 .so 里的偏移，和归档里 foo.o 的地址不必相同。"
