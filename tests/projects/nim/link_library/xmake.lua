set_project("link_libs")
add_rules("mode.debug", "mode.release")

add_requires("zlib", {system = false})
add_requires("stb", {system = false})

target("headers")
    set_kind("headeronly")
    add_files("headers/*.h")
    add_includedirs("headers")

target("executablestatic")
    set_kind("binary")
    add_files("mainlib.nim")
    add_deps("staticlib")
    add_packages("zlib", "stb")
    if is_plat("linux") then
        add_syslinks("pthread", "m")
    end

target("executableshared")
    set_kind("binary")
    add_files("maindll.nim")
    add_deps("sharedlib")
    if is_plat("linux") then
        add_syslinks("pthread", "m")
    end

target("staticlib")
    set_kind("static")
    add_files("static.nim")
    add_includedirs("inc")
    add_headerfiles("inc/*.h")
    if is_plat("linux") then
        add_syslinks("pthread", "m")
    end
    add_deps("headers")

target("sharedlib")
    set_kind("shared")
    add_files("shared.nim")
    add_includedirs("inc")
    add_headerfiles("inc/*.h")
    if is_plat("linux") then
        add_syslinks("pthread", "m")
    end
    add_deps("headers")
