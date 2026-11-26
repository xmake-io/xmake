add_rules("mode.debug", "mode.release")
set_languages("c++20")

target("a")
    set_kind("static")

    add_files("a.cppm", {public = true})
    add_files("a.cpp")
