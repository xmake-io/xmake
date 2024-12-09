target("cli")

    -- disable this target if only build libaries
    if has_config("onlylib") then
        set_default(false)
    end

    -- add deps
    add_deps("xmake")

    -- make as a binary
    set_kind("binary")
    set_basename("xmake")
    set_targetdir("$(buildir)")

    -- add definitions
    add_defines("__tb_prefix__=\"xmake\"")

    -- add includes directory
    add_includedirs("$(projectdir)", "$(projectdir)/src")

    -- add common source files
    add_files("**.c")

    -- add resource files (it will be enabled after publishing new version)
    if is_plat("windows") then
        add_files("*.rc")
    end

    -- add links
    if is_plat("windows") then
        add_syslinks("ws2_32", "advapi32", "shell32")
        add_ldflags("/export:malloc", "/export:free", "/export:memmove")
    elseif is_plat("android") then
        add_syslinks("m", "c")
    elseif is_plat("macosx") and is_config("runtime", "luajit") then
        add_ldflags("-all_load", "-pagezero_size 10000", "-image_base 100000000")
    elseif is_plat("mingw") then
        add_ldflags("-static-libgcc", {force = true})
    elseif is_plat("haiku") then
        add_syslinks("pthread", "network", "m", "c")
    else
        add_syslinks("pthread", "dl", "m", "c")
    end

    -- enable xp compatibility mode
    if is_plat("windows") then
        if is_arch("x86") then
            add_ldflags("/subsystem:console,5.01")
        else
            add_ldflags("/subsystem:console,5.02")
        end
    end

    -- add install files
    if is_plat("windows") then
        add_installfiles("$(projectdir)/../LICENSE.md")
        add_installfiles("$(projectdir)/../NOTICE.md")
        add_installfiles("$(projectdir)/../xmake/(**.lua)")
        add_installfiles("$(projectdir)/../xmake/(scripts/**)")
        add_installfiles("$(projectdir)/../xmake/(templates/**)")
        add_installfiles("$(projectdir)/../scripts/xrepo.bat")
        add_installfiles("$(projectdir)/../scripts/xrepo.ps1")
        set_prefixdir("/", {bindir = "/"})
        after_install(function (target)
            os.cp(path.join(os.programdir(), "winenv"), target:installdir())
        end)
    else
        add_installfiles("$(projectdir)/../(xmake/**.lua)", {prefixdir = "share"})
        add_installfiles("$(projectdir)/../(xmake/scripts/**)", {prefixdir = "share"})
        add_installfiles("$(projectdir)/../(xmake/templates/**)", {prefixdir = "share"})
        add_installfiles("$(projectdir)/../scripts/xrepo.sh", {prefixdir = "bin", filename = "xrepo"})
    end

    before_installcmd(function (target, batchcmds, opt)
        -- we need to avoid some old files interfering with xmake's module import.
        local package = opt.package
        if target:is_plat("windows") then
            batchcmds:rmdir(package:installdir("actions"))
            batchcmds:rmdir(package:installdir("core"))
            batchcmds:rmdir(package:installdir("includes"))
            batchcmds:rmdir(package:installdir("languages"))
            batchcmds:rmdir(package:installdir("modules"))
            batchcmds:rmdir(package:installdir("platforms"))
            batchcmds:rmdir(package:installdir("plugins"))
            batchcmds:rmdir(package:installdir("repository"))
            batchcmds:rmdir(package:installdir("rules"))
            batchcmds:rmdir(package:installdir("templates"))
            batchcmds:rmdir(package:installdir("scripts"))
            batchcmds:rmdir(package:installdir("themes"))
            batchcmds:rmdir(package:installdir("toolchains"))
        end
    end)

