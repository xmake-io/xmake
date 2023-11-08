add_rules("mode.debug", "mode.release")

includes("@builtin/xpack")

xpack("test")
    set_description("hello")

target("test")
    set_kind("binary")
    add_files("src/*.cpp")


