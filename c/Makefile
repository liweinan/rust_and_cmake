# 同一份 foo.c，编出静态库和共享库。
# call_rust 不放进 all。根 Makefile 先 cargo build -p rust_lib，再 make -C c call_rust。
# 在 Linux 容器里跑：产物是 build/libfoo.a 和 build/libfoo.so。

CC ?= gcc
CFLAGS ?= -fPIC -Wall
BUILD := build
# 根目录传入 target/debug 的绝对路径。单独在 c/ 里 make 时，默认向上找。
RUST_LIB_DIR ?= $(abspath ../target/debug)

.PHONY: all clean call_rust

all: $(BUILD)/libfoo.a $(BUILD)/libfoo.so

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/foo.o: foo.c | $(BUILD)
	$(CC) $(CFLAGS) -c foo.c -o $@

$(BUILD)/libfoo.a: $(BUILD)/foo.o
	ar rcs $@ $(BUILD)/foo.o

$(BUILD)/libfoo.so: foo.c | $(BUILD)
	$(CC) $(CFLAGS) -shared foo.c -o $@

# -l:librust_lib.so 指定文件名，避免同目录的 librust_lib.a 被选中。
# 可执行文件只记录 librust_lib.so，运行时靠 LD_LIBRARY_PATH。
$(BUILD)/call_rust: call_rust.c | $(BUILD)
	$(CC) -Wall -o $@ call_rust.c -L $(RUST_LIB_DIR) -l:librust_lib.so

$(BUILD)/call_rust_static: call_rust.c | $(BUILD)
	$(CC) -Wall -o $@ call_rust.c $(RUST_LIB_DIR)/librust_lib.a

call_rust: $(BUILD)/call_rust $(BUILD)/call_rust_static

clean:
	rm -rf $(BUILD)
