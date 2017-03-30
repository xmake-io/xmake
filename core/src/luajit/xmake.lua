-- add target
target("luajit")

    -- make as a static library
    set_kind("static")

    -- set warning all and disable error
    set_warnings("all")

    -- set the object files directory
    set_objectdir("$(buildir)/.objs")

    -- add headers
    add_headers("src/(*.h)")
    set_headerdir("$(buildir)/luajit")

    -- add include directories
    add_includedirs("src", "src/autogen/$(plat)/$(arch)")

    -- add the common source files
    add_files("src/*.c|ljamalg.c|luajit.c") 
    add_files("src/autogen/$(plat)/$(arch)/*.s")
       
    -- disable jit compiler?
--    add_defines("LUAJIT_DISABLE_JIT")
