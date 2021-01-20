add_rules("mode.release", "mode.debug")

target("test")
    set_kind("static")
    add_files("src/*.c", "src/*.cpp")
    if is_plat("macosx") then
        add_files("src/*.m", "src/*.mm")
    end

target("demo")
    set_kind("binary")
    add_deps("test")
    add_files("src/main.cpp")
    if is_plat("macosx") then
        add_defines("MACOSX")
    end

target("demo2")
    set_kind("binary")
    add_files("src/main2.cpp", "src/*.d")
    if not is_plat("macosx") then
        set_enabled(false)
    end

