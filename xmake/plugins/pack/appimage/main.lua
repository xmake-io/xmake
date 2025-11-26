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
    local desktop_content = string.format([[
[Desktop Entry]
Type=Application
Name=%s
Comment=%s
Exec=usr/bin/%s
%sCategories=Utility;
]], apptitle, appdescription, main_executable, icon_line)
    io.writefile(desktopfile, desktop_content)
end

-- create AppRun script
function _create_apprun_script(appdir, main_executable)
    local apprun = path.join(appdir, "AppRun")
    local apprun_content = string.format([[
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
exec "${HERE}/usr/bin/%s" "$@"
]], main_executable)
    io.writefile(apprun, apprun_content)
    os.vrunv("chmod", {"+x", apprun})
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
            os.files(path.join(bindir, "*"), function (file, isdir)
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
function _pack_appimage(package)

    -- check platform
    assert(package:is_plat("linux"), "appimage format only supports Linux platform!")

    -- find appimagetool
    local appimagetool = find_tool("appimagetool")
    if not appimagetool then
        raise("appimagetool not found! Please install appimagetool.")
    end

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

    -- create AppRun script
    _create_apprun_script(appdir, main_executable)

    -- create AppImage using appimagetool
    os.vrunv(appimagetool.program, {appdir, outputfile}, {envs = {APPIMAGE_EXTRACT_AND_RUN = "1"}})

    -- verify AppImage was created
    assert(os.isfile(outputfile), "generate %s failed!", outputfile)
end

function main(package)
    cprint("packing %s .. ", package:outputfile())
    _pack_appimage(package)
end

