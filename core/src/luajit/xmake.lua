-- disable jit compiler for redhat and centos
local jit = true
local autogendir = "autogen/$(plat)/jit/$(arch)"
if os.isfile("/etc/redhat-release") then
    jit = false
    autogendir = "autogen/$(plat)/nojit/$(arch)"
end

-- add target
target("luajit")

    -- make as a static library
    set_kind("static")

    -- set warning all and disable error
    set_warnings("all")

    -- disable c99(/TP) for windows
    if is_plat("windows") then
        set_languages("c89")
    end

    -- add header files
    add_headerfiles("luajit/src/(*.h)")

    -- add include directories
    add_includedirs(autogendir)
    add_includedirs("luajit/src", {public = true})

    -- add the common source files
    add_files("luajit/src/*.c|ljamalg.c|luajit.c") 
    if is_plat("windows") then
        add_files(autogendir .. "/lj_vm.obj")
    else
        add_files(autogendir .. "/*.S")
    end

    -- disable jit compiler?
    if not jit then
        add_defines("LUAJIT_DISABLE_JIT")
    end

    -- enable lua5.2 compat, @see http://luajit.org/extensions.html
    --[[
    add_defines("LUAJIT_ENABLE_LUA52COMPAT")
    if not is_plat("windows") then
        add_cflags("-Wno-error=unused-function")
    end]]

       
