xpack("xmake")
    set_formats("nsis")
    set_description("A cross-platform build utility based on Lua. https://xmake.io")
    set_licensefile("../LICENSE.md")
    add_targets("demo")
    set_bindir(".")
    set_iconfile("src/demo/xmake.ico")

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
        local format = package:format()
        if package:is_plat("windows") and (format == "nsis" or format == "zip") then
            local winenv = path.join(os.programdir(), "winenv")
            if os.isdir(winenv) then
                package:add("installfiles", path.join(winenv, "**"), {rootdir = path.directory(winenv)})
            else
                -- TODO download
            end
        end
    end)

    add_nsis_installcmds("Enable Long Path", [[
  ${If} $NoAdmin == "false"
    ; Enable long path
    WriteRegDWORD ${HKLM} "SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1
  ${EndIf}]], {description = "Increases the maximum path length limit, up to 32,767 characters (before 256)."})

