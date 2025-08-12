
add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("mod")
    set_kind("static")
    add_files("src/*.mpp", {public = true})

