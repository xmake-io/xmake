-- These targets should compiled and linked concurrently.
add_rules("mode.release", "mode.debug", "mode.releasedbg")
set_policy("build.ccache", false)

target("first")
    set_kind("binary")
    add_files("1.cpp")
    set_languages("clatest", "cxx20")

target("second")
    set_kind("binary")
    add_files("2.cpp")
    set_languages("clatest", "cxx20")
