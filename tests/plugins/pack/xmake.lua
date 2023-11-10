set_version("1.0.0")
add_rules("mode.debug", "mode.release")

includes("@builtin/xpack")

target("test")
    set_kind("binary")
    add_files("src/*.cpp")

xpack("test")
    set_formats("nsis")
    set_description("hello")
    add_targets("test")

    on_installcmd(function (package)
    end)

