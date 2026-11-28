#!/bin/sh
# 在容器的 bash 里查看 c/Makefile 编出的静态库和共享库，
# 以及 static_link、dylib_link 这两个 Rust 程序实际链上了哪一份 libfoo。
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

echo
echo "== ldd：问动态加载器这份 ELF 运行时要打开哪些共享库 =="

# ldd 只对已经链接好的 ELF 有意义。libfoo.a 是 ar 归档，加载器打不开它。
echo
echo "$ ldd c/build/libfoo.a"
ldd c/build/libfoo.a || true
note "not a dynamic executable。归档还没有动态段，ldd 列不出依赖。"

# libfoo.so 的 NEEDED 是 libc.so.6。ldd 把这个名字解析成系统里的文件。
# linux-vdso 由内核映射。ld-linux 是动态加载器自己。
run ldd c/build/libfoo.so
note "libc.so.6 指向系统里的那份。箭头左边是库名，右边是加载器找到的文件。"

# static_link 把 libfoo.a 收进可执行文件，ldd 的列表里没有 libfoo.so。
# dylib_link 只记下 libfoo.so 这个名字。LD_LIBRARY_PATH 告诉加载器到 c/build 找它。
# 这两个程序由 ./scripts/build.sh 编出。还没有的话先跑构建。
if [ -x target/debug/static_link ] && [ -x target/debug/dylib_link ]; then
    run ldd target/debug/static_link
    note "static_link 的列表里没有 libfoo.so。libfoo.a 的代码已经在这个可执行文件里。它仍然动态链接 libc。"
    echo
    echo "$ LD_LIBRARY_PATH=c/build ldd target/debug/dylib_link"
    LD_LIBRARY_PATH=c/build ldd target/debug/dylib_link
    note "dylib_link 记下 libfoo.so。LD_LIBRARY_PATH=c/build 时，ldd 把它解析到 c/build/libfoo.so。"
else
    note "static_link 和 dylib_link 还没编出来。先跑 ./scripts/build.sh，再看这两份程序的 ldd。"
fi

echo
echo "== Rust 程序链了哪一份 libfoo =="

# cargo rustc -v 在已经编过时只说 Fresh，不再打印链接命令。
# 换一个临时 target 目录，让这次编译一定会执行。产物放在 /tmp，不改仓库里的 target/。
# -C link-arg=-Wl,-t 把 -t 交给 ld，让它打印实际打开的库文件。
# rustc 自己根据 #[link] 选择 libfoo.a 或 libfoo.so，cargo 打出的 rustc 命令行里没有这个文件名。
show_rustc_link() {
    package=$1
    linked=$2
    dir=$3
    echo
    echo "$ cargo rustc -p $package -v --target-dir $dir -- -L native=$ROOT/c/build -C link-arg=-Wl,-t"
    rm -rf "$dir"
    cargo rustc -p "$package" -v --target-dir "$dir" -- -L native="$ROOT/c/build" -C link-arg=-Wl,-t 2>&1 \
        | grep libfoo \
        || true
    note "ld 的 -t 列出它打开的文件。$package 打开的是 $linked。"
}

show_rustc_link static_link /src/c/build/libfoo.a /tmp/show-static
show_rustc_link dylib_link /src/c/build/libfoo.so /tmp/show-dylib

# 下面几条看已经编进 target/debug 的那两个程序。符号和 NEEDED 记在文件里。
if [ -x target/debug/static_link ] && [ -x target/debug/dylib_link ]; then
    # nm -g 只看全局符号。
    # static_link 里 testcall 是 T：libfoo.a 的代码已经收进这个文件。
    # dylib_link 里 testcall 是 U：名字还没解析，运行时到 libfoo.so 里找。
    echo
    echo "$ nm -g target/debug/static_link | grep testcall"
    nm -g target/debug/static_link | grep testcall
    note "T 表示函数定义在这个可执行文件里。这是静态链接 libfoo.a 的结果。"
    echo
    echo "$ nm -g target/debug/dylib_link | grep testcall"
    nm -g target/debug/dylib_link | grep testcall
    note "U 表示这里只用了名字。定义在 libfoo.so 里。"

    # readelf -d 读动态段。NEEDED 是运行时要打开的共享库。
    # 静态链接的程序没有 libfoo.so。动态链接的程序有。
    echo
    echo "$ readelf -d target/debug/static_link | grep NEEDED"
    readelf -d target/debug/static_link | grep NEEDED
    note "static_link 的 NEEDED 只有 libgcc_s.so.1 和 libc.so.6，没有 libfoo.so。"
    echo
    echo "$ readelf -d target/debug/dylib_link | grep NEEDED"
    readelf -d target/debug/dylib_link | grep NEEDED
    note "dylib_link 的第一条 NEEDED 是 libfoo.so。"

    # objdump -p 也打印动态段，和 readelf -d 的 NEEDED 是同一份信息。
    echo
    echo "$ objdump -p target/debug/static_link | grep NEEDED"
    objdump -p target/debug/static_link | grep NEEDED
    note "objdump -p 的 NEEDED 和上面 readelf -d 一致，static_link 没有 libfoo.so。"
    echo
    echo "$ objdump -p target/debug/dylib_link | grep NEEDED"
    objdump -p target/debug/dylib_link | grep NEEDED
    note "objdump -p 也能看到 dylib_link 依赖 libfoo.so。"

    # objdump -T 只看动态符号表。UND 表示未定义，和 nm 里的 U 是同一件事。
    echo
    echo "$ objdump -T target/debug/dylib_link | grep testcall"
    objdump -T target/debug/dylib_link | grep testcall
    note "UND 是动态符号表里的未定义符号。运行时由 libfoo.so 提供。"
else
    note "static_link 和 dylib_link 还没编出来。先跑 ./scripts/build.sh，再看 nm、readelf 和 objdump。"
fi

echo
echo "== ld：gcc 写共享库时调用的链接器 =="

# cc -shared 编译 foo.c，再把链接交给 ld。
# -Wl,-trace 原样传给 ld，让它打印打开的每一个文件。
# 输出里有 libc.so.6 和 ld-linux：这就是 .so 的运行时依赖从哪来的。
echo
echo "$ cc -shared -o /tmp/libfoo-ld.so c/foo.c -Wl,-trace"
cc -shared -o /tmp/libfoo-ld.so c/foo.c -Wl,-trace
note "cc 把 -trace 交给 ld。libc.so.6 和 ld-linux 是 ld 写进这份共享库的运行时依赖。"
