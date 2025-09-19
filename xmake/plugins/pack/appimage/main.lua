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
import("detect.sdks.find_qt")
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
    local linuxdeploy = find_tool("linuxdeploy")
    if not linuxdeploy then
        local linuxdeploy_url = "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
        local linuxdeploy_path = path.join(os.tmpdir(), "linuxdeploy")
        if not os.isfile(linuxdeploy_path) then
            os.runv("wget", {"-O", linuxdeploy_path, linuxdeploy_url})
            os.runv("chmod", {"+x", linuxdeploy_path})
        end
        linuxdeploy = {program = linuxdeploy_path}
    end
    return linuxdeploy
end

-- get linuxqtdeploy tool
function _get_linuxdeployqt()
    local linuxdeployqt = find_tool("linuxdeployqt")
    if not linuxdeployqt then
        local linuxdeployqt_url = "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
        local linuxdeployqt_path = path.join(os.tmpdir(), "linuxdeployqt")
        if not os.isfile(linuxdeployqt_path) then
            os.runv("wget", {"-O", linuxdeployqt_path, linuxdeployqt_url})
            os.runv("chmod", {"+x", linuxdeployqt_path})
        end
        linuxdeployqt = {program = linuxdeployqt_path}
    end
    return linuxdeployqt
end

-- collect Qt dependencies with linuxdeployqt (rewritten)
function _collect_qt_deps_with_linuxdeployqt(package, appdir, linuxdeployqt)

    -- get qt info
    local qt = assert(find_qt(), "qt not found!")  
    local qt_version = assert(qt.sdkver, "Failed to determine Qt version. Please ensure your Qt installation is correctly detected by xmake.")  
    local main_executable = path.join(appdir, "usr/bin", package:name())
    local desktop_file = path.join(appdir, package:name() .. ".desktop")

    if not os.isfile(main_executable) then
        return false
    end
    if not os.isfile(desktop_file) then
        return false
    end

    -- set environment variables 
    local envs = {}
    if qt.bindir then
        envs.PATH = qt.bindir .. ":" .. (os.getenv("PATH") or "")
    end
    if qt.libdir then
        envs.LD_LIBRARY_PATH = qt.libdir .. ":" .. (os.getenv("LD_LIBRARY_PATH") or "")
    end
    if qt.pluginsdir then
        envs.QT_PLUGIN_PATH = qt.pluginsdir
    end

    -- set Qt installation directory
    if qt.sdkdir then
        envs.QTDIR = qt.sdkdir
    end

    -- build linuxdeployqt command arguments
    local args = { desktop_file, "-bundle-non-qt-libs" }
    table.insert(args, "-verbose=2")
    
    -- if Qt version is 6, add specific options
    if qt_version and qt_version:startswith("6") then
        table.insert(args, "-qmldir=" .. (qt.qmldir or path.join(qt.sdkdir, "qml")))
    elseif qt_version and qt_version:startswith("5") then
        -- add Qt5 specific options
        if qt.qmldir and os.isdir(qt.qmldir) then
            table.insert(args, "-qmldir=" .. qt.qmldir)
        end
    end
    -- execute linuxdeployqt
    local ok, err = os.iorunv(linuxdeployqt.program, args, {curdir = appdir, envs = envs})
    if not ok then
        return false
    end

    -- validate result: check collected libraries and plugins
    local lib_dir = path.join(appdir, "usr/lib")
    local plugins_dir = path.join(appdir, "usr/plugins")
    
    local success = false
    
    -- check library directory
    if os.isdir(lib_dir) then
        local collected_libs = os.files(path.join(lib_dir, "libQt*.so*"))
        -- print("Qt libraries collected:", #collected_libs)
        if #collected_libs > 0 then
            success = true
        end
    else
        wprint("Warning: Library directory not created: %s", lib_dir)
    end
    -- check plugins directory
    if os.isdir(plugins_dir) then
        local collected_plugins = os.files(path.join(plugins_dir, "**"))
        -- print("Qt plugins collected:", #collected_plugins)
        if #collected_plugins > 0 then
            success = true
        end
    else
        wprint("Warning: Plugins directory not created: %s", plugins_dir)
    end
    -- final validation: check if main executable has Qt dependencies
    if success then
        local ldd_output = os.iorunv("ldd", {main_executable})
        if ldd_output then
            local missing_qt_libs = {}
            for line in ldd_output:gmatch("[^\r\n]+") do
                local lib_name = line:match("(libQt%w+%.so[%d%.]*)")
                if lib_name then
                    local lib_path = line:match("=> ([^%s]+)")
                    if lib_path and lib_path:find("not found") then
                        table.insert(missing_qt_libs, lib_name)
                    elseif lib_path then
                        local normalized_lib_path = path.normalize(path.absolute(lib_path, appdir))
                        if not normalized_lib_path:startswith(lib_dir) then
                            wprint("Warning: Qt library not from AppDir: %s -> %s", lib_name, lib_path)
                        end
                    end
                end
            end
            if #missing_qt_libs > 0 then
                success = false
            end
        end
    end
    return success
end

-- get appimage output file
function _get_appimage_file(package)
    local filename = string.format("%s-%s-x86_64.AppImage", package:name(), package:version())
    return path.absolute(path.join(path.directory(package:outputfile() or ""), filename))
end

function _is_qt_project(package)
    -- Method 3: Check for Qt libraries in links
    local links = package:get("links")
    if links then
        for _, link in ipairs(links) do
            if link:lower():find("qt", 1, true) then
                return true
            end
        end
    end
    -- Method 4: Check executable for Qt dependencies using ldd
    local main_executable = nil
    
    -- Try to find the main executable path
    local install_rootdir = package:install_rootdir()
    if install_rootdir then
        local bin_dir = path.join(install_rootdir, "bin")
        if os.isdir(bin_dir) then
            local exe_path = path.join(bin_dir, package:name())
            if os.isfile(exe_path) then
                main_executable = exe_path
            end
        end
    end
    
    -- If we couldn't find it in install dir, check if it exists in build output
    if not main_executable then
        local outputfile = package:outputfile()
        if outputfile and os.isfile(outputfile) then
            main_executable = outputfile
        end
    end
    
    if main_executable and os.isfile(main_executable) then
        local ldd_output = os.iorunv("ldd", {main_executable})
        if ldd_output then
            -- Check for Qt libraries in ldd output
            if ldd_output:lower():find("libqt", 1, true) or 
                ldd_output:lower():find("qt5", 1, true) or 
                ldd_output:lower():find("qt6", 1, true) then    
                return true
            end
        end
    end

    -- Method 5: Check source files for Qt headers/includes
    local srcfiles, _ = package:sourcefiles()
    for _, srcfile in ipairs(srcfiles or {}) do
        if srcfile:endswith(".cpp") or srcfile:endswith(".cc") or srcfile:endswith(".cxx") then
            if os.isfile(srcfile) then
                local content = io.readfile(srcfile)
                if content and (content:find("#include.*[Qq][Tt]") or 
                    content:find("#include.*<Q") or
                    content:find("QApplication", 1, true) or
                    content:find("QWidget", 1, true) or
                    content:find("QMainWindow", 1, true)) then
                    return true
                end
            end
        end
    end

    return false
end

-- translate the file path for AppDir structure
function _translate_filepath(package, filepath, appdir)
    local install_rootdir = package:install_rootdir()
    
    -- translate to relative path
    if filepath:startswith(install_rootdir) then
        local relative_path = path.relative(filepath, install_rootdir)
        -- translate to relative path
        if relative_path:startswith("usr/") then
            relative_path = relative_path:sub(5) 
        end
        -- map to AppDir's usr directory structure
        if relative_path:startswith("bin/") then
            return path.join(appdir, "usr", relative_path)
        elseif relative_path:startswith("lib/") then
            return path.join(appdir, "usr", relative_path)
        elseif relative_path:startswith("share/") then
            return path.join(appdir, "usr", relative_path)
        elseif relative_path:startswith("include/") then
            return path.join(appdir, "usr", relative_path)
        else
            local filename = path.filename(filepath)
            local ext = path.extension(filename):lower()

            -- binary executable -> usr/bin
            if ext == "" or ext == ".exe" then
                return path.join(appdir, "usr", "bin", filename)
            -- library file -> usr/lib
            elseif ext == ".so" or ext == ".dylib" or ext == ".dll" then
                return path.join(appdir, "usr", "lib", filename)
            -- icon file -> usr/share/icons/hicolor
            elseif ext == ".png" or ext == ".svg" or ext == ".ico" or ext == ".xpm" then
                local icon_dir = path.join(appdir, "usr/share/icons/hicolor/256x256/apps")
                return path.join(icon_dir, filename)
            -- desktop file -> usr/share/applications
            elseif ext == ".desktop" then
                return path.join(appdir, "usr/share/applications", filename)
            -- other files -> usr/share/<package-name> or based on original path
            else
                local dirname = path.directory(relative_path)
                if dirname and dirname ~= "." then
                    return path.join(appdir, "usr", "share", package:name(), dirname, filename)
                else
                    return path.join(appdir, "usr", "share", package:name(), filename)
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
            return path.join(appdir, "usr", "bin", filename)
        -- library file
        elseif ext == ".so" or ext == ".dylib" or ext == ".dll" then
            return path.join(appdir, "usr", "lib", filename)
        -- icon file
        elseif ext == ".png" or ext == ".svg" or ext == ".ico" or ext == ".xpm" then
            local icon_dir = path.join(appdir, "usr/share/icons/hicolor/256x256/apps")
            return path.join(icon_dir, filename)
        else
            return path.join(appdir, "usr", "share", package:name(), filename)
        end
    end
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
    io.writefile(desktop_file, desktop_content)
    return desktop_file
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
    return apprun_file
end


-- copy icon file
function _copy_icon(package, appdir)
    local iconfile = package:get("iconfile")
    local iconname = package:get("iconname") or package:name()
    
    if iconfile and os.isfile(iconfile) then
        -- 复制图标到usr/share/icons/hicolor目录
        local icon_dir = path.join(appdir, "usr/share/icons/hicolor/256x256/apps")
        os.mkdir(icon_dir)
        local icon_dst = path.join(icon_dir, iconname .. path.extension(iconfile))
        os.cp(iconfile, icon_dst)
        
        -- 同时复制到AppDir根目录供.desktop文件使用
        local root_icon = path.join(appdir, iconname .. path.extension(iconfile))
        os.cp(iconfile, root_icon)
        
        return icon_dst
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

-- manually collect common dependencies using ldd
function _collect_deps_manually(package, appdir)
    
    local main_executable = path.join(appdir, "usr/bin", package:name())
    if not os.isfile(main_executable) then
        return false
    end
    
    -- get dependencies using ldd
    local ldd_output = os.iorunv("ldd", {main_executable})
    if not ldd_output then
        return false
    end
    
    local lib_dir = path.join(appdir, "usr/lib")
    os.mkdir(lib_dir)
    
    -- parse ldd output and copy libraries
    for line in ldd_output:gmatch("[^\r\n]+") do
        local lib_path = line:match("=> ([^%s]+)")
        if lib_path and lib_path ~= "(0x" and os.isfile(lib_path) then
            -- skip system libraries that shouldn't be bundled
            local lib_name = path.filename(lib_path)
            local skip_libs = {
                "libc.so", "libm.so", "libdl.so", "libpthread.so",
                "librt.so", "libresolv.so", "libutil.so", "libnsl.so",
                "ld-linux-x86-64.so", "libgcc_s.so", "libstdc++.so"
            }
            
            local should_skip = false
            for _, skip_lib in ipairs(skip_libs) do
                if lib_name:find(skip_lib, 1, true) then
                    should_skip = true
                    break
                end
            end
            
            if not should_skip and not lib_path:startswith("/lib/") and not lib_path:startswith("/lib64/") then
                local dst_path = path.join(lib_dir, lib_name)
                if not os.isfile(dst_path) then
                    os.cp(lib_path, dst_path)
                end
            end
        end
    end
    return true
end

-- pack appimage package
function _pack_appimage(appimagetool, package)
    local is_qt = _is_qt_project(package)
    
    -- create temporary AppDir
    local appdir_name = package:name() .. ".AppDir"
    local appdir = path.join(os.tmpdir(), appdir_name)
    os.tryrm(appdir)
    
    -- create AppDir structure
    os.mkdir(appdir)
    os.mkdir(path.join(appdir, "usr"))
    os.mkdir(path.join(appdir, "usr/bin"))
    os.mkdir(path.join(appdir, "usr/lib"))
    os.mkdir(path.join(appdir, "usr/share"))
    os.mkdir(path.join(appdir, "usr/share/applications"))
    os.mkdir(path.join(appdir, "usr/share/icons"))
    os.mkdir(path.join(appdir, "usr/share/icons/hicolor"))
    os.mkdir(path.join(appdir, "usr/share/icons/hicolor/256x256"))
    os.mkdir(path.join(appdir, "usr/share/icons/hicolor/256x256/apps"))
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
    local deps_collected = false
    
    if is_qt then
        -- Qt projects use linuxdeployqt to collect dependencies
        local linuxdeployqt = _get_linuxdeployqt()
        if linuxdeployqt then
            deps_collected = _collect_qt_deps_with_linuxdeployqt(package, appdir, linuxdeployqt)
        else
            print("linuxdeployqt not available, will try fallback methods")
        end
    end

    -- If not a Qt project or Qt tool failed, use linuxdeploy
    if not deps_collected then
        local linuxdeploy = _get_linuxdeploy()
        if linuxdeploy then
            deps_collected = _collect_deps_with_linuxdeploy(package, appdir, linuxdeploy)
        else
            print("linuxdeploy not available")
        end
    end
    
    -- use manual method as fallback
    if not deps_collected then
        _collect_deps_manually(package, appdir)
    end
    
    -- check final lib directory content
    local lib_dir = path.join(appdir, "usr/lib")

    -- use appimagetool to build final AppImage
    local appimage_file = package:outputfile() or _get_appimage_file(package)
    os.tryrm(appimage_file)
    
    -- set architecture environment variable
    local arch = package:get("arch") or "x86_64"
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