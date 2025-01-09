target("xmake")
    set_kind("static")

    -- add deps
    add_deps("sv", "lz4")
    if namespace then
        add_deps("tbox::tbox")
    else
        add_deps("tbox")
    end
    if is_config("runtime", "luajit") then
        add_deps("luajit")
    else
        add_deps("lua")
    end
    if has_config("lua_cjson") then
        add_deps("lua-cjson")
    end
    if is_plat("windows") and has_config("pdcurses") then
        add_deps("pdcurses")
    end

    -- add definitions
    add_defines("__tb_prefix__=\"xmake\"")
    if is_mode("debug") then
        add_defines("__tb_debug__", {public = true})
    end

    -- set the auto-generated config.h
    set_configdir("$(buildir)/$(plat)/$(arch)/$(mode)")
    add_configfiles("xmake.config.h.in")

    -- add includes directory
    add_includedirs("..", {interface = true})
    add_includedirs("$(buildir)/$(plat)/$(arch)/$(mode)", {public = true})
    add_includedirs("../xxhash")
    add_includedirs("$(projectdir)/../xmake/scripts/module")

    -- add header files
    add_headerfiles("../(xmake/*.h)")
    add_headerfiles("../(xmake/prefix/*.h)")
    add_headerfiles("$(buildir)/$(plat)/$(arch)/$(mode)/xmake.config.h", {prefixdir = "xmake"})

    -- add the common source files
    add_files("**.c|winos/*.c")
    if is_plat("windows", "msys", "mingw", "cygwin") then
        add_files("winos/*.c")
    end

    -- add options
    add_options("readline")
    if is_plat("windows") then
        add_options("pdcurses")
    else
        add_options("curses")
    end

    -- add definitions
    if is_plat("windows") then
        add_defines("UNICODE", "_UNICODE")
    end

    -- embed all script files
    add_rules("utils.bin2c", {linewidth = 16, extensions = ".xmz"})
    on_config(function (target)
        import("utils.archive.archive")
        if has_config("embed") then
            local archivefile = path.join(target:autogendir(), "bin2c", "xmake.xmz")
            print("archiving %s ..", archivefile)
            os.tryrm(archivefile)
            local rootdir = path.normalize(path.join(os.projectdir(), "..", "xmake"))
            archive(archivefile, rootdir, {recurse = true, curdir = rootdir})
            target:add("files", archivefile)
            target:add("defines", "XM_EMBED_ENABLE=1")
        end
    end)
