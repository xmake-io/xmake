cmake_minimum_required(VERSION 3.13.0)
project(foo_demo LANGUAGES C CXX ASM)

add_library(foo STATIC "")
target_sources(foo PRIVATE
    src/interface.c
)

