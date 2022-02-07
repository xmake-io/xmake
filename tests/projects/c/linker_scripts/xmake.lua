add_rules("mode.debug", "mode.release")

target("test")
    add_deps("foo")
    set_kind("binary")
    add_files("src/main.c")
    add_files("src/main.lds")

target("foo")
    set_kind("shared")
    add_files("src/foo.c")
    if is_plat("windows") then
        add_files("src/foo.def")
    else
        add_files("src/foo.map")
    end

