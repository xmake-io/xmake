-- add target
target("luajit")

    -- make as a static library
    set_kind("static")

    -- set warning all and disable error
    set_warnings("all")

    -- set the object files directory
    set_objectdir("$(buildir)/.objs")

    -- add include directories
    add_includedirs("src")

    -- add the common source files
    add_files("src/**.c") 
       
