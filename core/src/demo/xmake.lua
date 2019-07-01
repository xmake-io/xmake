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
    add_includedirs("$(projectdir)", "$(projectdir)/src")

    -- add the common source files
    add_files("**.c")

    -- add the resource files (it will be enabled after publishing new version)
    if is_plat("windows") then
        add_files("*.rc")
    end

    -- add links
    if is_plat("windows") then
        add_links("ws2_32", "advapi32", "shell32")
    elseif is_plat("android") then
        add_links("m", "c")
    elseif is_plat("macosx") then
        add_ldflags("-all_load", "-pagezero_size 10000", "-image_base 100000000")
    else
        add_links("pthread", "dl", "m", "c")
    end

    -- enable xp compatibility mode
    if is_plat("windows") then
        if is_arch("x86") then
            add_ldflags("/subsystem:console,5.01")
        else
            add_ldflags("/subsystem:console,5.02")
        end
    end

    -- copy target to the build directory
    after_build(function (target)
        os.cp(target:targetfile(), "$(buildir)")
    end)

