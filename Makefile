# 仓库根目录的构建。
# c/Makefile 编出 libfoo.a 和 libfoo.so。
# cxx/Makefile 编出 libbar.a 和 libbar.so。
# cargo rustc 后面的参数原样传给 rustc。
# rustc -L native=目录：到该目录找 lib*.a / lib*.so。native 表示系统库，不是 Rust rlib。
# rustc -C：codegen 选项。-C link-arg=-lstdc++ 把 -lstdc++ 追加到链接命令末尾。
# 下面的 $(MAKE) -C c 是 Make 的参数，表示进到该目录再 make，和 rustc 的 -C 无关。
# 链静态库还是共享库，由各自 main.rs 里的 #[link] 决定。

.PHONY: all libs static_link dylib_link static_link_cxx dylib_link_cxx clean

all: static_link dylib_link static_link_cxx dylib_link_cxx

libs:
	$(MAKE) -C c
	$(MAKE) -C cxx

static_link: libs
	cargo rustc -p static_link -- -L native=$(CURDIR)/c/build

dylib_link: libs
	cargo rustc -p dylib_link -- -L native=$(CURDIR)/c/build

# libbar.a 引用了 libstdc++，但归档文件不会记录这个依赖。
# -C link-arg 追加在链接命令末尾，-lstdc++ 因此排在 libbar.a 后面。
static_link_cxx: libs
	cargo rustc -p static_link_cxx -- -L native=$(CURDIR)/cxx/build -C link-arg=-lstdc++

# libbar.so 在 g++ -shared 时已经依赖 libstdc++.so。
dylib_link_cxx: libs
	cargo rustc -p dylib_link_cxx -- -L native=$(CURDIR)/cxx/build

clean:
	$(MAKE) -C c clean
	$(MAKE) -C cxx clean
	cargo clean
