add_rules("mode.debug", "mode.release")
add_frameworks("Foundation", "CoreFoundation")

if is_os("macosx", "ios") then
    add_mxflags("-fobjc-arc")
end

target("test")
    set_kind("shared")
    add_files("src/test.m")

target("demo")
    set_kind("binary")
    add_deps("test")
    add_files("src/main.m")
