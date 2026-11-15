#!/bin/sh
# 进入仓库根目录，执行根目录的 Makefile。
# Makefile 先编 libfoo 和 libbar，再 cargo rustc，最后让 C/C++ 链接 librust_lib。
# 没有 build.rs。CPU 架构就是当前容器的架构。
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$ROOT"

echo "== make：libfoo、libbar、librust_lib，然后链接调用方 =="
make
