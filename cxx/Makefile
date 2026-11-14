# 同一份 bar.cpp，编出静态库和共享库。
# g++ -shared 会把 libstdc++.so 记进 libbar.so 的依赖。
# libbar.a 只是目标文件的打包，最终链接可执行文件时还要自己加上 -lstdc++。

CXX ?= g++
CXXFLAGS ?= -fPIC -Wall
BUILD := build

.PHONY: all clean

all: $(BUILD)/libbar.a $(BUILD)/libbar.so

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/bar.o: bar.cpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -c bar.cpp -o $@

$(BUILD)/libbar.a: $(BUILD)/bar.o
	ar rcs $@ $(BUILD)/bar.o

$(BUILD)/libbar.so: bar.cpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -shared bar.cpp -o $@

clean:
	rm -rf $(BUILD)
