add_rules("mode.release", "mode.debug")
set_languages("c++20")

namespace("foo", function()
    target("dep")
        set_kind("static")
        add_files("src/hello.mpp", "src/mod.mpp", {public = true})
        add_files("src/hello_impl.cpp", "src/mod_impl.cpp")

    target("binary")
        set_kind("binary")
        add_files("src/main.cpp")
        add_deps("dep")
end)

