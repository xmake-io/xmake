xpack("xmake")
    set_homepage("https://xmake.io")
    set_title("Xmake build utility ($(arch))")
    set_description("A cross-platform build utility based on Lua.")
    set_copyright("Copyright (C) 2015-present, TBOOX Open Source Group")
    set_licensefile("../LICENSE.md")
    set_formats("nsis", "zip")
    add_targets("demo")
    set_bindir(".")
    set_iconfile("src/demo/xmake.ico")

    add_components("LongPath")

    on_load(function (package)
        local arch = package:arch()
        if package:is_plat("windows") then
            if arch == "x64" then
                arch = "win64"
            elseif arch == "x86" then
                arch = "win32"
            end
        end
        package:set("basename", "xmake-v$(version)." .. arch)
        local format = package:format()
        if format == "zip" then
            package:set("prefixdir", "xmake")
        end
    end)

    before_package(function (package)
        import("net.http")
        import("utils.archive")
        import("core.base.global")
        local format = package:format()
        if package:is_plat("windows") and (format == "nsis" or format == "zip") then
            local winenv = path.join(os.programdir(), "winenv")
            if os.isdir(winenv) then
                package:add("installfiles", path.join(winenv, "**"), {rootdir = path.directory(winenv)})
            else
                local arch = package:arch()
                local url_7z = "https://github.com/xmake-mirror/7zip/releases/download/19.00/7z19.00-" .. arch .. ".zip"
                local url_curl = "https://curl.se/windows/dl-8.2.1_11/curl-8.2.1_11-win32-mingw.zip"
                local archive_7z = path.join(package:buildir(), "7z.zip")
                local archive_curl = path.join(package:buildir(), "curl.zip")
                local tmpdir_7z = path.join(package:buildir(), "7z")
                local tmpdir_curl = path.join(package:buildir(), "curl")
                local winenv_bindir = path.join(package:buildir(), "winenv", "bin")
                os.mkdir(winenv_bindir)
                http.download(url_7z, archive_7z, {insecure = global.get("insecure-ssl")})
                if archive.extract(archive_7z, tmpdir_7z) then
                    os.cp(path.join(tmpdir_7z, "*"), winenv_bindir)
                else
                    raise("extract 7z.zip failed!")
                end
                http.download(url_curl, archive_curl, {insecure = global.get("insecure-ssl")})
                if archive.extract(archive_curl, tmpdir_curl) then
                    os.cp(path.join(tmpdir_curl, "*", "bin", "*.exe"), winenv_bindir)
                    os.cp(path.join(tmpdir_curl, "*", "bin", "*.crt"), winenv_bindir)
                else
                    raise("extract curl.zip failed!")
                end
                winenv = path.directory(winenv_bindir)
                package:add("installfiles", path.join(winenv, "**"), {rootdir = path.directory(winenv)})
            end
        end
    end)

xpack_component("LongPath")
    set_title("Enable Long Path")
    set_description("Increases the maximum path length limit, up to 32,767 characters (before 256).")
    on_installcmd(function (component, batchcmds)
        batchcmds:rawcmd("nsis", [[
  ${If} $NoAdmin == "false"
    ; Enable long path
    WriteRegDWORD ${HKLM} "SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1
  ${EndIf}]])
    end)

xpack("xmakesrc")
    set_formats("src_zip", "src_targz")
    set_basename("xmake-v$(version)")
    on_load(function (package)
        local format = package:format()
        if format == "src_zip" then
            package:set("extension", ".zip")
        elseif format == "src_targz" then
            package:set("extension", ".tar.gz")
        end
    end)
    on_package(function (package)
        import("devel.git")
        import("utils.archive")
        print("packing %s", package:outputfile())
        local tmpdir = os.tmpfile() .. ".dir"
        local repodir = path.join(tmpdir, "repo")
        local srcdir = path.join(package:rootdir(), "xmakesrc")
        local topdir = path.join(srcdir, "xmake-" .. package:version())
        os.tryrm(repodir)
        os.tryrm(topdir)
        os.cp(path.directory(path.absolute(os.projectdir())), repodir)
        git.clean({repodir = repodir, force = true, all = true})
        git.reset({repodir = repodir, hard = true})
        if os.isfile(path.join(repodir, ".gitmodules")) then
            git.submodule.clean({repodir = repodir, force = true, all = true})
            git.submodule.reset({repodir = repodir, hard = true})
        end
        os.mkdir(path.join(topdir, "scripts"))
        os.vcp(path.join(repodir, "core"), topdir)
        os.vcp(path.join(repodir, "xmake"), topdir)
        os.vcp(path.join(repodir, "*.md"), topdir)
        os.vcp(path.join(repodir, "configure"), topdir)
        os.vcp(path.join(repodir, "scripts", "*.sh"), path.join(topdir, "scripts"))
        os.vcp(path.join(repodir, "scripts", "man"), path.join(topdir, "scripts"))
        os.vcp(path.join(repodir, "scripts", "debian"), path.join(topdir, "scripts"))
        os.vcp(path.join(repodir, "scripts", "msys"), path.join(topdir, "scripts"))
        os.rm(path.join(topdir, "core", "src", "tbox", "tbox", "src", "demo"))
        os.rm(path.join(topdir, "core", "src", "luajit"))
        os.rm(path.join(topdir, "core", "src", "pdcurses"))

        -- archive files
        local oldir = os.cd(srcdir)
        local archivefiles = os.files("**")
        os.cd(oldir)
        archive.archive(path.absolute(package:outputfile()), archivefiles, {curdir = srcdir, compress = "best"})
        os.tryrm(tmpdir)
    end)

