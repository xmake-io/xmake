cmake_minimum_required(VERSION 3.10)
project(test)

foreach(i RANGE 1 1000)
    add_executable(test${i} src/main.cpp)
endforeach()
