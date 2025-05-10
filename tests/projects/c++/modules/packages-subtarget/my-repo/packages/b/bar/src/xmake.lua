add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("bar")
    set_kind("static")
    add_headerfiles("include/(**.hpp)")
    add_includedirs("include")
    add_files("*.cpp")
    add_files("*.mpp", { public = true })
