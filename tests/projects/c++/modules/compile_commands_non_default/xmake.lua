add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("mod")
    set_kind("static")
    set_default(false)
    add_files("src/mod.mpp", {public = true})

target("mod_test")
    set_kind("binary")
    set_default(false)
    add_deps("mod")
    add_files("src/main.cpp")
