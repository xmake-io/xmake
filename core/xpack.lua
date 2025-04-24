xpack("xmake")
    set_homepage("https://xmake.io")
    set_title("Xmake build utility ($(arch))")
    set_description("A cross-platform build utility based on Lua.")
    set_copyright("Copyright (C) 2015-present, TBOOX Open Source Group")
    set_author("ruki <waruqi@gmail.com>")
    set_licensefile("../LICENSE.md")
    set_formats("nsis", "wix", "zip")
    add_targets("cli")
    set_bindir(".")
    set_iconfile("src/cli/xmake.ico")

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
        if package:is_plat("windows") and (format == "nsis" or format == "wix" or format == "zip") then
            local winenv = path.join(os.programdir(), "winenv")
            if false then -- os.isdir(winenv) then
                package:add("installfiles", path.join(winenv, "**"), {rootdir = path.directory(winenv)})
            else
                local arch = package:arch()
                local url_7z = "https://github.com/xmake-mirror/7zip/releases/download/24.08/7z24.08-" .. arch .. ".zip"
                local curl_version = "8.11.0_4"
                local url_curl = "https://curl.se/windows/dl-" .. curl_version .. "/curl-" .. curl_version
                if package:is_arch("x64", "x86_64") then
                    url_curl = url_curl .. "-win64-mingw.zip"
                elseif package:is_arch("arm64") then
                    url_curl = url_curl .. "-win64a-mingw.zip"
                else
                    url_curl = url_curl .. "-win32-mingw.zip"
                end
                local archive_7z = path.join(package:buildir(), "7z.zip")
                local archive_curl = path.join(package:buildir(), "curl.zip")
                local tmpdir_7z = path.join(package:buildir(), "7z")
                local tmpdir_curl = path.join(package:buildir(), "curl")
                local winenv_bindir = path.join(package:buildir(), "winenv", "bin")
                os.mkdir(winenv_bindir)
                http.download(url_7z, archive_7z, {insecure = global.get("insecure-ssl")})
                archive.extract(archive_7z, tmpdir_7z)
                os.cp(path.join(tmpdir_7z, "*"), winenv_bindir)
                http.download(url_curl, archive_curl, {insecure = global.get("insecure-ssl")})
                archive.extract(archive_curl, tmpdir_curl)
                os.cp(path.join(tmpdir_curl, "*", "bin", "*.exe"), winenv_bindir)
                os.cp(path.join(tmpdir_curl, "*", "bin", "*.crt"), winenv_bindir)
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
        batchcmds:rawcmd("wix", [[
    <RegistryKey Root="HKLM" Key="SYSTEM\CurrentControlSet\Control\FileSystem">
        <RegistryValue Type="integer" Name="LongPathsEnabled" Value="1" KeyPath="yes"/>
    </RegistryKey>
        ]])
    end)

xpack("xmakesrc")
    set_homepage("https://xmake.io")
    set_title("Xmake build utility ($(arch))")
    set_description("A cross-platform build utility based on Lua.")
    set_copyright("Copyright (C) 2015-present, TBOOX Open Source Group")
    set_author("ruki <waruqi@gmail.com>")
    set_formats("srczip", "srctargz", "runself", "srpm", "deb")
    set_basename("xmake-v$(version)")
    set_prefixdir("xmake-$(version)")
    set_license("Apache-2.0")
    before_package(function (package)
        import("devel.git")

        local rootdir = path.join(os.tmpfile(package:basename()) .. ".dir", "repo")
        if not os.isdir(rootdir) then
            os.tryrm(rootdir)
            os.cp(path.directory(os.projectdir()), rootdir)

            git.clean({repodir = rootdir, force = true, all = true})
            git.reset({repodir = rootdir, hard = true})
            if os.isfile(path.join(rootdir, ".gitmodules")) then
                git.submodule.clean({repodir = rootdir, force = true, all = true})
                git.submodule.reset({repodir = rootdir, hard = true})
            end
        end

        local extraconf = {rootdir = rootdir}
        package:add("sourcefiles", path.join(rootdir, "core/**|src/pdcurses/**|src/luajit/**|src/tbox/tbox/src/demo/**"), extraconf)
        package:add("sourcefiles", path.join(rootdir, "xmake/**|scripts/vsxmake/**"), extraconf)
        package:add("sourcefiles", path.join(rootdir, "*.md"), extraconf)
        package:add("sourcefiles", path.join(rootdir, "configure"), extraconf)
        package:add("sourcefiles", path.join(rootdir, "scripts/*.sh"), extraconf)
        package:add("sourcefiles", path.join(rootdir, "scripts/man/**"), extraconf)
        package:add("sourcefiles", path.join(rootdir, "scripts/debian/**"), extraconf)
        package:add("sourcefiles", path.join(rootdir, "scripts/msys/**"), extraconf)
    end)

    on_buildcmd(function (package, batchcmds)
        local format = package:format()
        if format == "srpm" or format == "deb" then
            batchcmds:runv("./configure")
            batchcmds:runv("make", {"-j4"})
        end
    end)

    on_installcmd(function (package, batchcmds)
        local format = package:format()
        if format == "runself" then
            batchcmds:runv("./scripts/get.sh", {"__local__"})
        elseif format == "srpm" or format == "deb" then
            batchcmds:runv("make", {"install", path(package:install_rootdir(), function (p) return "PREFIX=" .. p end)})
        end
    end)
