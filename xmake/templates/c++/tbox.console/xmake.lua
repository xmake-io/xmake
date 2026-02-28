set_xmakever("2.3.6")
set_warnings("all", "error")
set_languages("c99", "cxx11")
add_cxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing")
add_mxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing")

add_rules("mode.release", "mode.debug")
add_requires("tbox", {debug = is_mode("debug")})

if is_plat("windows") then
    if is_mode("release") then
        add_cxflags("-MT")
    elseif is_mode("debug") then
        add_cxflags("-MTd")
    end
    add_ldflags("-nodefaultlib:msvcrt.lib")
end

includes("src")

${FAQ}
