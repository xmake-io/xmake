xpack("xmake")
    set_formats("nsis")
    set_description("A cross-platform build utility based on Lua. https://xmake.io")
    set_licensefile("../LICENSE.md")
    add_targets("demo")
    set_bindir(".")
    set_iconfile("src/demo/xmake.ico")
    if set_nsis_displayname then
        set_nsis_displayname("Xmake build utility ($(arch))")
    end

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

    add_nsis_installcmds("Enable Long Path", [[
  ${If} $NoAdmin == "false"
    ; Enable long path
    WriteRegDWORD ${HKLM} "SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1
  ${EndIf}]], {description = "Increases the maximum path length limit, up to 32,767 characters (before 256)."})

