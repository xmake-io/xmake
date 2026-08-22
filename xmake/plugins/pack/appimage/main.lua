--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")
import("private.action.run.runenvs")
import(".batchcmds")

-- handle icon file
function _handle_icon(package, appdir, appname)
    local iconname = nil
    local iconfile = package:get("iconfile")
    if iconfile then
        local iconpath = path.absolute(iconfile)
        if not os.isfile(iconpath) then
            raise("icon file not found: %s", iconfile)
        end
        local ext = path.extension(iconpath)
        -- AppImage only supports .png, .svg, .xpm
        if ext ~= ".png" and ext ~= ".svg" and ext ~= ".xpm" then
            raise("appimage format only supports .png, .svg, or .xpm icon files, but got: %s", ext)
        end
        iconname = appname .. ext
        -- copy to AppDir root (required for AppImage)
        os.cp(iconpath, path.join(appdir, iconname))
        -- also copy to standard location
        local iconsdir = path.join(appdir, "usr", "share", "icons", "hicolor", "256x256", "apps")
        os.mkdir(iconsdir)
        os.cp(iconpath, path.join(iconsdir, iconname))
    end
    return iconname
end

-- create desktop file
function _create_desktop_file(package, appdir, appname, apptitle, appdescription, main_executable, iconname)
    local desktopfile = path.join(appdir, appname .. ".desktop")
    local icon_line = ""
    if iconname then
        icon_line = string.format("Icon=%s\n", appname)
    end
    local version_line = ""
    local version = package:version()
    if version then
        version_line = string.format("X-AppImage-Version=%s\n", version)
    end
    local desktop_content = string.format([[
[Desktop Entry]
Type=Application
Name=%s
Comment=%s
Exec=usr/bin/%s
%s%sCategories=Utility;
]], apptitle, appdescription, main_executable, icon_line, version_line)
    io.writefile(desktopfile, desktop_content)
end



function _env_table_to_export_lines(env_table)
    local lines = {}
    for k, v in pairs(env_table) do
        table.insert(lines, string.format('export %s="%s"', k, v))
    end
    return lines
end


-- create AppRun script
function _create_apprun_script(appdir, main_executable, runarg_table,export_path_env, export_other_env)
    local apprun = path.join(appdir, "AppRun")

    local all_export_lines = {}
    for _, line in ipairs(export_path_env) do table.insert(all_export_lines, line) end
    for _, line in ipairs(export_other_env) do table.insert(all_export_lines, line) end



    local template = [[
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"



{{export_statements}}

exec "$HERE/usr/bin/{{binary}}" {{runargs}} "$@"
]]

    local subs = {
        binary = main_executable,
        runargs = table.concat(runarg_table, " "),
        export_statements = table.concat(all_export_lines, "\n"),
    }

    local final = string.gsub(template, "{{(%w+)}}", function(key)
        return subs[key] or ""
    end)

    io.writefile(apprun, final)
    os.vrunv("chmod", { "+x", apprun })
end

-- get the appimagetool
function _get_appimagetool()
    -- enter the environments of appimagetool
    local oldenvs = packagenv.enter("appimage")

    -- find appimagetool
    local packages = {}
    local appimagetool = find_tool("appimagetool")
    if not appimagetool then
        table.join2(packages, install_packages("appimage"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not appimagetool then
        appimagetool = find_tool("appimagetool", { force = true })
    end
    assert(appimagetool, "appimagetool not found!")
    return appimagetool, oldenvs
end


function _get_envs(package)
    local args = nil
    local addenvs = {}
    local setenvs = {}
    for _, target in ipairs(package:targets()) do
        if target:is_binary() then
            args = target:get("runargs") or {}          -- 确保是表
            addenvs, setenvs = runenvs.make(target)     -- 返回两个表
            break   -- 只取第一个二进制目标
        end
    end
    -- 将 addenvs 和 setenvs 分别转换为 export 行数组
    local add_lines = _env_table_to_export_lines(addenvs)
    local set_lines = _env_table_to_export_lines(setenvs)
    return args, add_lines, set_lines
end

-- get main executable from package
function _get_main_executable(package, usrdir)
    local main_executable = nil
    local main_executable_path = nil

    -- try to find from targets first
    for _, target in ipairs(package:targets()) do
        if target:is_binary() then
            main_executable = target:basename()
            -- check if file exists in usr/bin
            local exec_path = path.join(usrdir, "bin", main_executable)
            if os.isfile(exec_path) then
                main_executable_path = exec_path
                break
            end
        end
    end

    -- fallback: find in bindir
    if not main_executable_path then
        local bindir = package:bindir()
        if bindir and os.isdir(bindir) then
            -- find executable files in bindir using os.files callback
            os.files(path.join(bindir, "*"), function(file, isdir)
                if not isdir and os.isfile(file) and not os.islink(file) and os.isexec(file) then
                    main_executable = path.filename(file)
                    main_executable_path = path.join(usrdir, "bin", main_executable)
                    if os.isfile(main_executable_path) then
                        return false
                    end
                end
                return true
            end)
        end
    end

    return main_executable, main_executable_path
end

-- pack appimage package
function _pack_appimage(package, appimagetool)
    -- check platform
    assert(package:is_plat("linux"), "appimage format only supports Linux platform!")

    -- archive binary files
    batchcmds.get_installcmds(package):runcmds()
    for _, component in table.orderpairs(package:components()) do
        if component:get("default") ~= false then
            batchcmds.get_installcmds(component):runcmds()
        end
    end

    -- get install root directory
    local rootdir = package:install_rootdir()
    assert(os.isdir(rootdir), "install root directory not found: %s", rootdir)

    -- get output file
    local outputfile = package:outputfile()
    os.tryrm(outputfile)

    -- create AppDir directory structure
    local builddir = package:builddir()
    local appdir = path.join(builddir, "AppDir")
    os.tryrm(appdir)
    os.mkdir(appdir)

    -- copy files to AppDir/usr
    local usrdir = path.join(appdir, "usr")
    os.cp(rootdir, usrdir)

    -- get main executable
    local main_executable, main_executable_path = _get_main_executable(package, usrdir)
    assert(main_executable and main_executable_path and os.isfile(main_executable_path),
        "main executable not found! Please ensure at least one binary target is added to xpack.")

    -- get application name and title
    local appname = package:name()
    local apptitle = package:title() or appname
    local appdescription = package:description() or ""

    -- handle icon file
    local iconname = _handle_icon(package, appdir, appname)

    -- create desktop file
    _create_desktop_file(package, appdir, appname, apptitle, appdescription, main_executable, iconname)

    --local targets = package:targets()

    local args, addenvs, setenvs = _get_envs(package)
    -- create AppRun script
    _create_apprun_script(appdir, main_executable,args,addenvs,setenvs)

    -- create AppImage using appimagetool
    os.vrunv(appimagetool, { appdir, outputfile }, { envs = { APPIMAGE_EXTRACT_AND_RUN = "1" } })

    -- verify AppImage was created
    assert(os.isfile(outputfile), "generate %s failed!", outputfile)
end

function main(package)
    -- only for linux
    if not is_host("linux") then
        return
    end

    cprint("packing %s .. ", package:outputfile())

    -- get appimagetool
    local appimagetool, oldenvs = _get_appimagetool()

    -- pack appimage package
    _pack_appimage(package, appimagetool.program)

    -- done
    os.setenvs(oldenvs)
end
