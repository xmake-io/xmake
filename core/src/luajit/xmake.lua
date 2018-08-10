-- disable jit compiler for redhat and centos
local jit = true
local autogendir = "src/autogen/$(plat)/jit/$(arch)"
if os.isfile("/etc/redhat-release") then
    jit = false
    autogendir = "src/autogen/$(plat)/nojit/$(arch)"
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
    else
	set_languages("gnu99")
    end

    -- set the object files directory
    set_objectdir("$(buildir)/.objs")

    -- add headers
    add_headers("src/(*.h)")
    set_headerdir("$(buildir)/luajit")

    -- add include directories
    add_includedirs("src", autogendir)

    -- add the common source files
    add_files("src/*.c|ljamalg.c|luajit.c") 
    if is_plat("windows") then
        add_files(autogendir .. "/lj_vm.obj")
    else
        add_files(autogendir .. "/*.S")
    end

    -- disable jit compiler?
    if not jit then
        add_defines("LUAJIT_DISABLE_JIT")
    end


       
