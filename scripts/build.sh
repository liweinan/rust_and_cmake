#!/bin/sh
# 进入仓库根目录，执行根目录的 Makefile。
# Makefile 先 make -C c，再对两个 crate 执行 cargo rustc。
# 没有 build.rs。CPU 架构就是当前容器的架构。
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$ROOT"

echo "== make：libfoo，然后 cargo rustc =="
make
