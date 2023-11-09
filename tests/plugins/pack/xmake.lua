add_rules("mode.debug", "mode.release")

includes("@builtin/xpack")

target("test")
    set_kind("binary")
    add_files("src/*.cpp")

xpack("test")
    add_formats("nsis")
    set_description("hello")
    add_targets("test")

    on_installcmd(function (package)
    end)

