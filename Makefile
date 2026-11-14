# 仓库根目录的构建。
# c/Makefile 编出 libfoo.a 和 libfoo.so。
# cargo rustc 后面的参数原样传给 rustc：-L 是库搜索路径。
# 链静态库还是共享库，由各自 main.rs 里的 #[link] 决定。

.PHONY: all libs static_link dylib_link clean

all: static_link dylib_link

libs:
	$(MAKE) -C c

static_link: libs
	cargo rustc -p static_link -- -L native=$(CURDIR)/c/build

dylib_link: libs
	cargo rustc -p dylib_link -- -L native=$(CURDIR)/c/build

clean:
	$(MAKE) -C c clean
	cargo clean
