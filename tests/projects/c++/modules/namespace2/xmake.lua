add_rules("mode.release", "mode.debug")
set_languages("c++20")

namespace("bar", function()
    target("dep")
        set_kind("static")
        add_files("src/hello.mpp", "src/mod.mpp", {public = true})
        add_files("src/hello_impl.cpp", "src/mod_impl.cpp")
end)

namespace("foo", function()
    target("binary")
        set_kind("binary")
        add_files("src/main.cpp")
        add_deps("bar::dep")
end)

