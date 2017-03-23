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
    add_includedirs("$(projectdir)")
    add_includedirs("$(projectdir)/src")

    -- add links and directory
    add_links("xmake")
    add_linkdirs("$(buildir)")

    -- add packages
    add_packages("tbox", "luajit", "base")

    -- add the common source files
    add_files("**.c") 
       
