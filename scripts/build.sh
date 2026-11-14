#!/bin/sh
# 先编 C 库，再让 Cargo 链接。CPU 架构就是当前容器的架构。
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$ROOT"

echo "== 1. make: libfoo.a 与 libfoo.so =="
make -C c

echo "== 2. cargo build =="
cargo build --workspace
