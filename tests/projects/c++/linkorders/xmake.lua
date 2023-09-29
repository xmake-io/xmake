add_rules("mode.debug", "mode.release")

if not is_host("bsd") then
    add_requires("libpng")
end

target("bar")
    set_kind("shared")
    add_files("src/foo.cpp")
    add_linkgroups("m", "pthread", {whole = true})

target("foo")
    set_kind("static")
    add_files("src/foo.cpp")
    add_packages("libpng", {public = true})

target("demo")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.cpp")
    if is_plat("linux", "macosx") then
        add_syslinks("pthread", "m", "dl")
    end
    if is_plat("macosx") then
        add_frameworks("Foundation", "CoreFoundation")
    end
    if is_host("bsd") then
        add_linkorders("framework::Foundation", "foo")
    else
        add_linkorders("framework::Foundation", "png16", "foo")
    end
    add_linkorders("dl", "linkgroup::syslib")
    add_linkgroups("m", "pthread", {name = "syslib"})


