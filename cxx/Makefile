# 同一份 bar.cpp，编出静态库和共享库。
# g++ -shared 会把 libstdc++.so 记进 libbar.so 的依赖。
# libbar.a 只是目标文件的打包，最终链接可执行文件时还要自己加上 -lstdc++。
# call_rust 不放进 all。根 Makefile 先 cargo build -p rust_lib，再 make -C cxx call_rust。

CXX ?= g++
CXXFLAGS ?= -fPIC -Wall
BUILD := build
# 根目录传入 target/debug 的绝对路径。单独在 cxx/ 里 make 时，默认向上找。
RUST_LIB_DIR ?= $(abspath ../target/debug)

.PHONY: all clean call_rust

all: $(BUILD)/libbar.a $(BUILD)/libbar.so

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/bar.o: bar.cpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -c bar.cpp -o $@

$(BUILD)/libbar.a: $(BUILD)/bar.o
	ar rcs $@ $(BUILD)/bar.o

$(BUILD)/libbar.so: bar.cpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -shared bar.cpp -o $@

# -l:librust_lib.so 指定文件名，避免同目录的 librust_lib.a 被选中。
$(BUILD)/call_rust_cxx: call_rust.cpp | $(BUILD)
	$(CXX) -Wall -o $@ call_rust.cpp -L $(RUST_LIB_DIR) -l:librust_lib.so

$(BUILD)/call_rust_static: call_rust.cpp | $(BUILD)
	$(CXX) -Wall -o $@ call_rust.cpp $(RUST_LIB_DIR)/librust_lib.a

call_rust: $(BUILD)/call_rust_cxx $(BUILD)/call_rust_static

clean:
	rm -rf $(BUILD)
