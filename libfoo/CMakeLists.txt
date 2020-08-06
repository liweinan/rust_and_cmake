cmake_minimum_required(VERSION 3.0)
project(LibFoo C)

add_library(foo STATIC foo.c)

install(TARGETS foo DESTINATION .)
