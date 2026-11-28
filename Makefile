# 仓库根目录的构建。
# c/Makefile 编出 libfoo.a 和 libfoo.so。
# cxx/Makefile 编出 libbar.a 和 libbar.so。
# cargo rustc 后面的参数原样传给 rustc。
# rustc -L native=目录：到该目录找 lib*.a / lib*.so。native 表示系统库，不是 Rust rlib。
# rustc -C：codegen 选项。-C link-arg=-lstdc++ 把 -lstdc++ 追加到链接命令末尾。
# 下面的 $(MAKE) -C c 是 Make 的参数，表示进到该目录再 make，和 rustc 的 -C 无关。
# 链静态库还是共享库，由各自 main.rs 里的 #[link] 决定。
# rust_lib 用 cargo 编出 librust_lib.a 和 librust_lib.so。
# 链接调用方的步骤在 c/Makefile、cxx/Makefile 的 call_rust 目标里。

.PHONY: all libs static_link dylib_link static_link_cxx dylib_link_cxx rust_lib call_rust clean

all: static_link dylib_link static_link_cxx dylib_link_cxx call_rust

libs:
	$(MAKE) -C c
	$(MAKE) -C cxx

# cargo rustc：编译这个包，并把后面的参数传给 rustc。
# -p static_link：工作区里的包名，对应目录 static_link/。
# --：这条横线之后只交给 rustc，cargo 自己不再解析。
# -L native=目录：让链接器到该目录找 libfoo.a。native 表示系统库，不是 Rust rlib。
# $(CURDIR) 是本 Makefile 所在目录，也就是仓库根目录，所以路径是绝对路径。
# 链 libfoo.a 还是 libfoo.so，不写在这里，由 static_link/src/main.rs 的 #[link(kind = "static")] 决定。
static_link: libs
	cargo rustc -p static_link -- -L native=$(CURDIR)/c/build

# 参数和上一条相同。-p dylib_link 编译 dylib_link/。
# 搜索目录仍是 c/build，因为 libfoo.so 和 libfoo.a 放在一起。
# 选中 libfoo.so 的是 dylib_link/src/main.rs 里的 #[link(kind = "dylib")]。
dylib_link: libs
	cargo rustc -p dylib_link -- -L native=$(CURDIR)/c/build

# libbar.a 引用了 libstdc++，但归档文件不会记录这个依赖。
# -C link-arg 追加在链接命令末尾，-lstdc++ 因此排在 libbar.a 后面。
static_link_cxx: libs
	cargo rustc -p static_link_cxx -- -L native=$(CURDIR)/cxx/build -C link-arg=-lstdc++

# libbar.so 在 g++ -shared 时已经依赖 libstdc++.so。
dylib_link_cxx: libs
	cargo rustc -p dylib_link_cxx -- -L native=$(CURDIR)/cxx/build

# crate-type 同时是 staticlib 和 cdylib。
rust_lib:
	cargo build -p rust_lib

call_rust: rust_lib
	$(MAKE) -C c call_rust RUST_LIB_DIR=$(CURDIR)/target/debug
	$(MAKE) -C cxx call_rust RUST_LIB_DIR=$(CURDIR)/target/debug

clean:
	$(MAKE) -C c clean
	$(MAKE) -C cxx clean
	cargo clean
