#!/bin/sh
# 动态库不在系统路径里。运行前把 c/build 和 cxx/build 放进 LD_LIBRARY_PATH。
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
export LD_LIBRARY_PATH="$ROOT/c/build:$ROOT/cxx/build${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

echo "== static_link =="
"$ROOT/target/debug/static_link"

echo "== dylib_link =="
"$ROOT/target/debug/dylib_link"

echo "== static_link_cxx =="
"$ROOT/target/debug/static_link_cxx"

echo "== dylib_link_cxx =="
"$ROOT/target/debug/dylib_link_cxx"
