-- add target
target("xmake")

    -- make as a static library
    set_kind("static")

    -- add deps
    add_deps("lcurses", "sv", "luajit", "tbox")

    -- add defines
    add_defines("__tb_prefix__=\"xmake\"")

    -- set the auto-generated config.h
    set_config_header("$(projectdir)/xmake.config.h", {prefix = "XM_CONFIG"})

    -- set the object files directory
    set_objectdir("$(buildir)/.objs")

    -- add includes directory
    add_includedirs("$(projectdir)", "$(buildir)/luajit")

    -- add packages
    add_packages("tbox")

    -- add the common source files
    add_files("**.c") 
  
    -- add readline
    add_options("readline")      
    if is_plat("windows") or is_option("curses") then
        add_defines("XM_CONFIG_API_HAVE_CURSES")
    end
 

