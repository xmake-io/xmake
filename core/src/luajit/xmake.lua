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

    -- set the object files directory
    set_objectdir("$(buildir)/.objs")

    -- add headers
    add_headers("src/(*.h)")
    set_headerdir("$(buildir)/luajit")

    -- add include directories
    add_includedirs("src", "src/autogen/$(plat)/$(arch)")

    -- add the common source files
    add_files("src/*.c|ljamalg.c|luajit.c") 
    if is_plat("windows") then
        add_files("src/autogen/$(plat)/$(arch)/lj_vm.obj")
    else
        add_files("src/autogen/$(plat)/$(arch)/*.s")
    end


       
