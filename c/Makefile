# 同一份 foo.c，编出静态库和共享库。
# 在 Linux 容器里跑：产物是 build/libfoo.a 和 build/libfoo.so。

CC ?= gcc
CFLAGS ?= -fPIC -Wall
BUILD := build

.PHONY: all clean

all: $(BUILD)/libfoo.a $(BUILD)/libfoo.so

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/foo.o: foo.c | $(BUILD)
	$(CC) $(CFLAGS) -c foo.c -o $@

$(BUILD)/libfoo.a: $(BUILD)/foo.o
	ar rcs $@ $(BUILD)/foo.o

$(BUILD)/libfoo.so: foo.c | $(BUILD)
	$(CC) $(CFLAGS) -shared foo.c -o $@

clean:
	rm -rf $(BUILD)
