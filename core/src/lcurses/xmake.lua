-- add target
target("lcurses")

    -- make as a static library
    set_kind("static")

    -- add deps
    add_deps("luajit")
    if is_plat("windows") then
        add_deps("pdcurses")
    end

    -- set the object files directory
    set_objectdir("$(buildir)/.objs")

    -- add includes directory
    add_includedirs("$(buildir)/luajit")

    -- add the common source files
    add_files("*.c") 
  
    -- add options
    add_options("curses")
