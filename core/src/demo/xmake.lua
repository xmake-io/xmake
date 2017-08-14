-- add target
target("demo")

    -- add deps
    add_deps("xmake")

    -- make as a binary 
    set_kind("binary")

    -- set basename of target file
    set_basename("xmake")

    -- add defines
    add_defines("__tb_prefix__=\"xmake\"")

    -- set the object files directory
    set_objectdir("$(buildir)/.objs")

    -- add includes directory
    add_includedirs("$(projectdir)", "$(projectdir)/src", "$(buildir)/luajit")

    -- link readline
    if not is_plat("windows") then
--        add_links("readline")
    end

    -- add packages
    add_packages("tbox", "base")

    -- add the common source files
    add_files("**.c") 
           
    -- for macosx
    if is_plat("macosx") then
        add_ldflags("-all_load", "-pagezero_size 10000", "-image_base 100000000")
    end

    -- add the resource files (it will be enabled after publishing new version)
    if is_plat("windows") then
        add_files("*.rc")
    end

