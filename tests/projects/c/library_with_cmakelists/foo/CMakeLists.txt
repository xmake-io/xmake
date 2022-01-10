cmake_minimum_required(VERSION 3.13.0)
project(foo LANGUAGES C CXX ASM)

add_library(foo STATIC "")
target_sources(foo PRIVATE
    src/foo.c
)
set_target_properties(foo PROPERTIES PUBLIC_HEADER src/foo.h)
include(GNUInstallDirs)
install(TARGETS foo
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

