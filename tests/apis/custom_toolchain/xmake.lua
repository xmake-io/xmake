add_rules("mode.debug", "mode.release")

set_toolchains("my-c6000")
add_toolchaindirs("toolchains")

target("test")
    set_kind("static")
    add_files("src/foo.cpp")

target("demo")
    set_kind("binary")
    add_deps("test")
    add_files("src/test.cpp")


