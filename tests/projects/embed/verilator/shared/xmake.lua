add_requires("verilator")

target("hello")
    add_rules("verilator.shared")
    set_toolchains("@verilator")
    add_files("src/*.v")

target("test")
    add_deps("hello")
    add_files("src/*.cpp")
