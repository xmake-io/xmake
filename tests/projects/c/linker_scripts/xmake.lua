add_rules("mode.debug", "mode.release")

target("test")
    add_deps("foo")
    set_kind("binary")
    add_files("src/main.c")
    if is_plat("linux") and is_arch("x86_64") then
        add_files("src/main.lds")
    end

target("foo")
    set_kind("shared")
    add_files("src/foo.c")
    if is_plat("windows", "mingw") then
        add_files("src/foo.def")
    else
        add_files("src/foo.map")
    end

