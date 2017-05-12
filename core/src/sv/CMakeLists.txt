cmake_minimum_required(VERSION 2.8.7 FATAL_ERROR)
project(sv)

if(CMAKE_VERSION VERSION_LESS "3.1")
    if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
        set(CMAKE_C_FLAGS "-std=c99 ${CMAKE_C_FLAGS}")
    endif()
else()
    set(CMAKE_C_STANDARD 99)
endif()

set(sv_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include)
set(sv_SOURCE_DIR  ${CMAKE_CURRENT_LIST_DIR}/src)
set(sv_TEST_DIR  ${CMAKE_CURRENT_LIST_DIR}/test)

file(GLOB sv_HEADERS ${sv_HEADERS} ${sv_INCLUDE_DIR}/*.h)
file(GLOB sv_SOURCES ${sv_SOURCES} ${sv_SOURCE_DIR}/*.c)

include_directories(${sv_INCLUDE_DIR})
add_library(${PROJECT_NAME} STATIC ${sv_SOURCES} ${sv_HEADERS})

enable_testing()
add_subdirectory(${sv_TEST_DIR})
