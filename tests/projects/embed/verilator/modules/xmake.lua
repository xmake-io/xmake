add_requires("verilator")

-- @see https://github.com/xmake-io/xmake/issues/7624
target("hello")
    add_rules("verilator.binary")
    set_toolchains("@verilator")
    set_languages("c++20")
    set_policy("build.c++.modules", true)
    add_files("src/*.v")
    add_files("src/*.cpp")
    add_files("src/*.mpp")
