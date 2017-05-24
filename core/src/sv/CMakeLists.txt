cmake_minimum_required(VERSION 2.8.7 FATAL_ERROR)
project(sv)

option(SHARED "Build as shared library" OFF)
option(COVERAGE "Turn on COVERAGE support" OFF)

if (COVERAGE AND NOT MSVC)
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} --coverage")
endif()

if(CMAKE_VERSION VERSION_LESS "3.1")
    if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
        set(CMAKE_C_FLAGS "-std=c99 ${CMAKE_C_FLAGS}")
    endif()
else()
    set(CMAKE_C_STANDARD 99)
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")
if(MSVC)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W3")
else()
    if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O0 -g3 -DDEBUG")
    else()
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3")
    endif()
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wextra -Werror -fomit-frame-pointer")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-missing-field-initializers -Wno-unused-parameter -Wno-unused-function")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-variable -Wno-unused-value -Wno-unused-result")
endif()

set(sv_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include)
set(sv_SOURCE_DIR  ${CMAKE_CURRENT_LIST_DIR}/src)
set(sv_TEST_DIR  ${CMAKE_CURRENT_LIST_DIR}/test)

file(GLOB sv_HEADERS ${sv_HEADERS} ${sv_INCLUDE_DIR}/*.h)
file(GLOB sv_SOURCES ${sv_SOURCES} ${sv_SOURCE_DIR}/*.c)

include_directories(${sv_INCLUDE_DIR})
if(SHARED)
    if(MSVC)
        set(CMAKE_FLAGS
            CMAKE_CXX_FLAGS
            CMAKE_CXX_FLAGS_DEBUG
            CMAKE_CXX_FLAGS_RELEASE
            CMAKE_C_FLAGS
            CMAKE_C_FLAGS_DEBUG
            CMAKE_C_FLAGS_RELEASE
        )
        foreach(CMAKE_FLAG ${CMAKE_FLAGS})
            string(REPLACE "/MD" "/MT" ${CMAKE_FLAG} "${${CMAKE_FLAG}}")
            string(REPLACE "/MDd" "/MTd" ${CMAKE_FLAG} "${${CMAKE_FLAG}}")
        endforeach()
    endif()

    add_library(${PROJECT_NAME} SHARED ${sv_SOURCES} ${sv_HEADERS})
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DSV_BUILD_DYNAMIC_LINK=1")
else()
    add_library(${PROJECT_NAME} STATIC ${sv_SOURCES} ${sv_HEADERS})
endif()
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DSV_COMPILE=1")

enable_testing()
add_subdirectory(${sv_TEST_DIR})

if(WIN32)
    set(CPACK_GENERATOR "WIX")
    set(CPACK_SOURCE_GENERATOR "ZIP")
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(CPACK_GENERATOR "PackageMake")
else()
    set(CPACK_GENERATOR "DEB;RPM")
    set(CPACK_SOURCE_GENERATOR "TGZ")
endif()

set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Lucas Abel")

set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_PACKAGE_VERSION_MAJOR "1")
set(CPACK_PACKAGE_VERSION_MINOR "0")
set(CPACK_PACKAGE_VERSION_PATCH "0")

set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_SOURCE_DIR}/README.md")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/UNLICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README.md")
set(CPACK_RESOURCE_FILE_WELCOME "${CMAKE_SOURCE_DIR}/README.md")

set(CPACK_SOURCE_IGNORE_FILES "${CMAKE_SOURCE_DIR}/build/;${CMAKE_SOURCE_DIR}/.git/")

set(CPACK_SYSTEM_NAME "")

include(CPack)
