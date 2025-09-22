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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      RubMaker
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.base.hashset")
import("lib.detect.find_tool")
import("lib.detect.find_file")
import("utils.archive")
import(".batchcmds")

-- get the appimagetool
function _get_appimagetool()
    local appimagetool = find_tool("appimagetool")
    if not appimagetool then
        assert(appimagetool, "appimagetool need to be downloaded!")
    end
    return appimagetool
end
-- get linuxdeploy tool
function _get_linuxdeploy()
    local linuxdeploy = assert(find_tool("linuxdeploy"), "linuxdeploy not found!Pease install it in Downloads folder.")
    return linuxdeploy
end
-- get appimage output file
function _get_appimage_file(package)
    local filename = string.format("%s-%s-x86_64.AppImage", package:name(), package:version())
    return path.absolute(path.join(path.directory(package:outputfile() or ""), filename))
end
-- translate the file path for AppDir structure
function _translate_filepath(package, filepath, appdir)
    local install_rootdir = package:install_rootdir()
    local dstpath = nil
    -- translate to relative path
    if filepath:startswith(install_rootdir) then
        local relative_path = path.relative(filepath, install_rootdir)
        -- translate to relative path
        if relative_path:startswith("usr/") then
            relative_path = relative_path:sub(5)
        end
        -- map to AppDir's usr directory structure
        if relative_path:startswith("bin/") then
            dstpath = path.join(appdir, "usr", relative_path)
        elseif relative_path:startswith("lib/") then
            dstpath = path.join(appdir, "usr", relative_path)
        elseif relative_path:startswith("share/") then
            dstpath = path.join(appdir, "usr", relative_path)
        elseif relative_path:startswith("include/") then
            dstpath = path.join(appdir, "usr", relative_path)
        else
            local filename = path.filename(filepath)
            local ext = path.extension(filename):lower()
            -- binary executable -> usr/bin
            if ext == "" or ext == ".exe" then
                dstpath = path.join(appdir, "usr", "bin", filename)
            -- library file -> usr/lib
            elseif ext == ".so" or ext == ".dylib" or ext == ".dll" then
                dstpath = path.join(appdir, "usr", "lib", filename)
            -- icon file -> usr/share/icons/hicolor
            elseif ext == ".png" or ext == ".svg" or ext == ".ico" or ext == ".xpm" then
                local icon_dir = path.join(appdir, "usr/share/icons/hicolor/256x256/apps")
                dstpath = path.join(icon_dir, filename)
            -- desktop file -> usr/share/applications
            elseif ext == ".desktop" then
                dstpath = path.join(appdir, "usr/share/applications", filename)
            -- other files -> usr/share/<package-name> or based on original path
            else
                local dirname = path.directory(relative_path)
                if dirname and dirname ~= "." then
                    dstpath = path.join(appdir, "usr", "share", package:name(), dirname, filename)
                else
                    dstpath = path.join(appdir, "usr", "share", package:name(), filename)
                end
            end
        end
    else
        local filename = path.filename(filepath)
        local ext = path.extension(filename):lower()
        if ext == ".cpp" or ext == ".c" or ext == ".h" or ext == ".hpp" or
           ext == ".py" or ext == ".js" or ext == ".java" or ext == ".go" then
            return nil
        -- binary file
        elseif ext == "" or ext == ".exe" then
            dstpath = path.join(appdir, "usr", "bin", filename)
        -- library file
        elseif ext == ".so" or ext == ".dylib" or ext == ".dll" then
            dstpath = path.join(appdir, "usr", "lib", filename)
        -- icon file
        elseif ext == ".png" or ext == ".svg" or ext == ".ico" or ext == ".xpm" then
            local icon_dir = path.join(appdir, "usr/share/icons/hicolor/256x256/apps")
            dstpath = path.join(icon_dir, filename)
        else
            dstpath = path.join(appdir, "usr", "share", package:name(), filename)
        end
    end
    if dstpath then
        os.mkdir(path.directory(dstpath))
    end
    return dstpath
end

-- get install command for AppDir
function _get_customcmd(package, appdir, installcmds, cmd)
    local opt = cmd.opt or {}
    local kind = cmd.kind
    if kind == "cp" then
        local srcfiles = os.files(cmd.srcpath)
        for _, srcfile in ipairs(srcfiles) do
            local dstfile = _translate_filepath(package, cmd.dstpath, appdir)
            if #srcfiles > 1 or path.islastsep(dstfile) then
                if opt.rootdir then
                    dstfile = path.join(dstfile, path.relative(srcfile, opt.rootdir))
                else
                    dstfile = path.join(dstfile, path.filename(srcfile))
                end
            end
            if dstfile then
                os.mkdir(path.directory(dstfile))
                table.insert(installcmds, string.format("install -Dpm0755 \"%s\" \"%s\"", srcfile, dstfile))
            end
        end
    elseif kind == "rm" then
        local filepath = _translate_filepath(package, cmd.filepath, appdir)
        table.insert(installcmds, string.format("rm -f \"%s\"", filepath))
    elseif kind == "rmdir" then
        local dir = _translate_filepath(package, cmd.dir, appdir)
        table.insert(installcmds, string.format("rm -rf \"%s\"", dir))
    elseif kind == "mv" then
        local srcpath = _translate_filepath(package, cmd.srcpath, appdir)
        local dstpath = _translate_filepath(package, cmd.dstpath, appdir)
        table.insert(installcmds, string.format("mv \"%s\" \"%s\"", srcpath, dstpath))
    elseif kind == "cd" then
        local dir = _translate_filepath(package, cmd.dir, appdir)
        table.insert(installcmds, string.format("cd \"%s\"", dir))
    elseif kind == "mkdir" then
        local dir = _translate_filepath(package, cmd.dir, appdir)
        table.insert(installcmds, string.format("mkdir -p \"%s\"", dir))
    elseif cmd.program then
        local argv = {}
        for _, arg in ipairs(cmd.argv) do
            if path.instance_of(arg) then
                arg = arg:clone():set(_translate_filepath(package, arg:rawstr(), appdir)):str()
            elseif path.is_absolute(arg) then
                arg = _translate_filepath(package, arg, appdir)
            end
            table.insert(argv, arg)
        end
        table.insert(installcmds, string.format("%s", os.args(table.join(cmd.program, argv))))
    end
end

-- get install commands for AppDir
function _get_installcmds(package, appdir, installcmds, cmds)
    for _, cmd in ipairs(cmds) do
        _get_customcmd(package, appdir, installcmds, cmd)
    end
end
-- create desktop file
function _create_desktop_file(package, appdir)
    local iconname = package:get("iconname") or package:name()
    local desktop_content = string.format([[
[Desktop Entry]
Type=Application
Name=%s
Comment=%s
Exec=%s
Icon=%s
Categories=%s
Version=1.0
]],
        package:get("title") or package:name(),
        package:get("description") or package:get("title") or package:name(),
        package:name(),
        iconname,
        package:get("category") or "Utility"
    )
    local desktop_file = path.join(appdir, package:name() .. ".desktop")
    -- mkdir desktop file
    os.mkdir(path.directory(desktop_file))
    io.writefile(desktop_file, desktop_content)
end
-- create AppRun script
function _create_apprun(package, appdir)
    local main_executable = path.join("usr", "bin", package:name())
    local apprun_content = string.format([[#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="${HERE}/usr/plugins"
export XDG_DATA_DIRS="${HERE}/usr/share:${XDG_DATA_DIRS}"
exec "${HERE}/%s" "$@"
]], main_executable)
    local apprun_file = path.join(appdir, "AppRun")
    io.writefile(apprun_file, apprun_content)
    os.runv("chmod", {"+x", apprun_file})
end
-- copy icon file
function _copy_icon(package, appdir)
    local iconfile = package:get("iconfile")
    local iconname = package:get("iconname") or package:name()
    if iconfile and os.isfile(iconfile) then
        local icon_dir = path.join(appdir, "usr/share/icons/hicolor/256x256/apps")
        os.mkdir(icon_dir)
        local icon_dst = path.join(icon_dir, iconname .. path.extension(iconfile))
        os.cp(iconfile, icon_dst)
        local root_icon = path.join(appdir, iconname .. path.extension(iconfile))
        os.cp(iconfile, root_icon)
    else
        return nil
    end
end
-- collect dependencies using linuxdeploy
function _collect_deps_with_linuxdeploy(package, appdir, linuxdeploy)
    local main_executable = path.join(appdir, "usr/bin", package:name())
    local desktop_file = path.join(appdir, package:name() .. ".desktop")
    local args = {
        "--appdir", appdir
    }
    -- add executable
    if os.isfile(main_executable) then
        table.insert(args, "--executable")
        table.insert(args, main_executable)
    end
    -- add desktop file
    if os.isfile(desktop_file) then
        table.insert(args, "--desktop-file")
        table.insert(args, desktop_file)
    end
    local ok, err = os.iorunv(linuxdeploy.program, args)
    if not ok then
        return false
    end
    -- check if linuxdeploy created lib directory
    local lib_dir = path.join(appdir, "usr/lib")
    if not os.isdir(lib_dir) then
        wprint("Warning: lib directory was not created by linuxdeploy!")
        return false
    end
    return true
end
-- pack appimage package
function _pack_appimage(appimagetool, package)
    -- create temporary AppDir
    local appdir_name = package:name() .. ".AppDir"
    local appdir = path.join(package:builddir(), appdir_name)
    print("Creating temporary AppDir: %s", appdir)
    os.tryrm(appdir)
    -- create AppDir structure
    os.mkdir(appdir)

    local original_prefixdir = package:get("prefixdir")
    package:set("prefixdir", "/usr")
    -- install files to AppDir
    local installcmds = {}
    _get_installcmds(package, appdir, installcmds, batchcmds.get_installcmds(package):cmds())
    for _, component in table.orderpairs(package:components()) do
        if component:get("default") ~= false then
            _get_installcmds(package, appdir, installcmds, batchcmds.get_installcmds(component):cmds())
        end
    end
    -- execute install commands
    for _, cmd in ipairs(installcmds) do
        os.exec(cmd)
    end
    if original_prefixdir then
        package:set("prefixdir", original_prefixdir)
    end
    -- copy source files
    local srcfiles, dstfiles = package:sourcefiles()
    for idx, srcfile in ipairs(srcfiles) do
        local dstfile = _translate_filepath(package, dstfiles[idx], appdir)
        if dstfile then
            os.vcp(srcfile, dstfile)
        end
    end
    for _, component in table.orderpairs(package:components()) do
        if component:get("default") ~= false then
            local srcfiles, dstfiles = component:sourcefiles()
            for idx, srcfile in ipairs(srcfiles) do
                local dstfile = _translate_filepath(package, dstfiles[idx], appdir)
                if dstfile then
                    os.vcp(srcfile, dstfile)
                end
            end
        end
    end
    -- create files required for AppImage
    _create_desktop_file(package, appdir)
    _create_apprun(package, appdir)
    _copy_icon(package, appdir)
    -- copy .desktop file to correct location
    local desktop_file = path.join(appdir, package:name() .. ".desktop")
    local desktop_usr_file = path.join(appdir, "usr/share/applications", package:name() .. ".desktop")
    os.cp(desktop_file, desktop_usr_file)
    -- use appropriate tools to collect dependencies
    local linuxdeploy = _get_linuxdeploy()
    local deps_collected = _collect_deps_with_linuxdeploy(package, appdir, linuxdeploy)
    -- check final lib directory content
    local lib_dir = path.join(appdir, "usr/lib")
    -- use appimagetool to build final AppImage
    local appimage_file = package:outputfile() or _get_appimage_file(package)
    os.tryrm(appimage_file)
    -- set architecture environment variable
    local arch = package:arch() or "x86_64"
    local envs = {ARCH = arch}
    os.vrunv(appimagetool.program, {appdir, appimage_file}, {envs = envs})
    -- clean up temporary directory
    os.tryrm(appdir)
end

function main(package)
    if not is_host("linux") then
        print("AppImage packaging is only supported on Linux")
        return
    end
    cprint("packing %s", package:outputfile() or _get_appimage_file(package))
    -- get appimagetool
    local appimagetool = _get_appimagetool()
    -- pack appimage
    _pack_appimage(appimagetool, package)
end