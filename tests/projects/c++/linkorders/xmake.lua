add_rules("mode.debug", "mode.release")

add_requires("libpng")

target("foo")
    set_kind("static")
    add_files("src/foo.cpp")
    add_packages("libpng", {public = true})

target("demo")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.cpp")
    if is_plat("linux", "macosx") then
        add_syslinks("pthread", "m")
    end


