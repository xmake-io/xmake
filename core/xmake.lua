set_project("xmake")
set_xmakever("3.0.5")
set_policy("build.progress_style", "multirow")
set_version("3.0.5", {build = "%Y%m%d"})

-- set all warnings as errors
set_warnings("all", "error")

-- set language: c99, c++11
set_languages("c99", "cxx11")

-- add release and debug modes
add_rules("mode.release", "mode.debug")
if is_mode("release") then
    set_optimize("smallest")
    if is_plat("windows") then
        add_ldflags("/LTCG")
    end
end

-- disable some compiler errors
add_cxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing", "-Wno-error=nullability-completeness", "-Wno-error=parentheses-equality")

-- add definitions
add_defines("_GNU_SOURCE=1", "_FILE_OFFSET_BITS=64", "_LARGEFILE_SOURCE")

-- ensure POSIX/XOPEN features are available on Solaris (for setenv, unsetenv, clock_gettime, etc.)
-- _XOPEN_SOURCE=600 implicitly sets _POSIX_C_SOURCE=200112L
if is_plat("solaris") then
    add_defines("_XOPEN_SOURCE=600")
end

-- add vectorexts
--[[
if is_arch("x86", "x64", "i386", "x86_64") then
    add_vectorexts("sse", "sse2", "sse3", "avx", "avx2")
elseif is_arch("arm.*") then
    add_vectorexts("neon")
end]]

-- for the windows platform (msvc)
if is_plat("windows") then
    set_runtimes("MT")
    add_links("kernel32", "user32", "gdi32")
end

-- for mode coverage
if is_mode("coverage") then
    add_ldflags("-coverage", "-fprofile-arcs", "-ftest-coverage")
end

-- set cosmocc toolchain, e.g. xmake f -p linux --cosmocc=y
if has_config("cosmocc") then
    add_requires("cosmocc")
    set_toolchains("@cosmocc")
    set_policy("build.ccache", false)
end

-- use cosmocc toolchain
option("cosmocc", {default = false, description = "Use cosmocc toolchain to build once and run anywhere."})

-- embed all script files
option("embed", {default = false, description = "Embed all script files."})

-- the runtime option
option("runtime")
    set_default("lua")
    set_description("Use luajit or lua runtime")
    set_values("luajit", "lua")
option_end()

-- the lua-cjson option
option("lua_cjson")
    set_default(true)
    set_description("Use lua-cjson as json parser")
option_end()

-- the readline option
option("readline")
    set_description("Enable or disable readline library")
    add_links("readline")
    add_cincludes("stdio.h", "readline/readline.h")
    add_cfuncs("readline")
    add_defines("XM_CONFIG_API_HAVE_READLINE")
    add_deps("cosmocc")
    after_check(function (option)
        if option:dep("cosmocc"):enabled() then
            option:enable(false)
        end
    end)
option_end()

-- the curses option
option("curses")
    set_description("Enable or disable curses library")
    add_defines("XM_CONFIG_API_HAVE_CURSES")
    add_deps("cosmocc")
    before_check(function (option)
        if is_plat("mingw") then
            option:add("cincludes", "ncursesw/curses.h")
            option:add("links", "ncursesw")
        else
            option:add("cincludes", "curses.h")
            option:add("links", "curses")
        end
    end)
    after_check(function (option)
        if option:dep("cosmocc"):enabled() or is_plat("solaris") then
            option:enable(false)
        end
    end)
option_end()

-- the pdcurses option
option("pdcurses")
    set_default(true)
    set_description("Enable or disable pdcurses library")
    add_defines("PDCURSES")
    add_defines("XM_CONFIG_API_HAVE_CURSES")
option_end()

-- only build xmake libraries for development?
option("onlylib")
    set_default(false)
    set_description("Only build xmake libraries for development")
option_end()

-- suppress warnings
if is_plat("windows") then
    add_defines("_CRT_SECURE_NO_WARNINGS")
    add_cxflags("/utf-8")
end

-- add projects
includes("src/sv", "src/lz4", "src/xmake", "src/cli")
if namespace then
    namespace("tbox", function ()
        includes("src/tbox")
    end)
else
    includes("src/tbox")
end
if has_config("lua_cjson") then
    includes("src/lua-cjson")
end
if is_config("runtime", "luajit") then
    includes("src/luajit")
else
    includes("src/lua")
end
if is_plat("windows") then
    includes("src/pdcurses")
end

-- add xpack
includes("@builtin/xpack")
if xpack then
    includes("xpack.lua")
end
