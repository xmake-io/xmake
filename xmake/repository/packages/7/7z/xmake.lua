package("7z")

    set_kind("binary")
    set_homepage("https://www.7-zip.org/")
    set_description("A file archiver with a high compression ratio.")

    if is_host("windows") then
        if is_arch("x64", "x86_64") then
            set_urls("https://github.com/xmake-mirror/7zip/releases/download/$(version)/7z$(version)-x64.zip",
                     "https://gitlab.com/xmake-mirror/7zip-releases/raw/master/7z$(version)-x64.zip")
            add_versions("19.00", "fc21cf510d70a69bfa8e5b0449fe0a054fb76e2f8bd568364821f319c8b1d86d")
            add_versions("18.05", "e6e2d21e2c482f1b1c5a6d21ed80800ce1273b902cf4b9afa68621545540ee2f")
        else
            set_urls("https://github.com/xmake-mirror/7zip/releases/download/$(version)/7z$(version)-x86.zip",
                     "https://gitlab.com/xmake-mirror/7zip-releases/raw/master/7z$(version)-x86.zip")
            add_versions("19.00", "f84fab081a2d8a6b5868a2eaf01cd56017363fb24560259cea80567f8062334f")
            add_versions("18.05", "544c37bebee30437aba405071484e0ac6310332b4bdabe4ca7420a800d4b4b5e")
        end
    else
        set_urls("https://github.com/xmake-mirror/7zip/archive/refs/tags/$(version).tar.gz",
                 "https://github.com/xmake-mirror/7zip.git")
        add_versions("21.02", "b2a4c5bec8207508b26f94507f62f5a79c57ae9ab77dbf393f3b2fc8eef2e382")
        add_patches("21.02", path.join(os.scriptdir(), "patches", "21.02", "backport-21.03-fix-for-GCC-10.patch"), "f1d8fa0bbb25123b28e9b2842da07604238b77e51b918260a369f97c2f694c89")
    end

    on_install("macosx", "linux", function (package)
        -- Clang has some indentation warnings that fails compilation using -Werror, remove it
        io.replace("CPP/7zip/7zip_gcc.mak", "CFLAGS_WARN_WALL = -Wall -Werror -Wextra", "CFLAGS_WARN_WALL = -Wall -Wextra", {plain = true})

        os.cd("CPP/7zip/Bundles/Alone2")
        os.vrun("make -j -f makefile.gcc")

        local bin = package:installdir("bin")
        os.cp("_o/7zz", bin)
        os.ln(bin .. "/7zz", bin .. "/7z")
    end)

    on_install("windows", function (package)
        os.cp("*", package:installdir("bin"))

        --[[
        Build code for windows

        local archdir = package:is_arch("x64", "x86_64") and "x64" or "x86"
        os.cd("CPP/7zip/Bundles/Alone2")
        local configs = {"-f", "makefile"}
        table.insert(configs, "PLATFORM=" .. archdir)
        import("package.tools.nmake").build(package, configs)

        local bin = package:installdir("bin")
        os.cp(archdir .. "/7zz.exe", bin .. "/7z.exe")
        ]]
    end)

    on_test(function (package)
        os.vrun("7z --help")
    end)
