cmake_minimum_required(VERSION 3.13.0)
project(foo LANGUAGES C CXX ASM)

add_library(foo STATIC "")
target_sources(foo PRIVATE
    src/foo.c
)

