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
import("core.base.semver")
import("lib.detect.find_tool")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")
import("detect.sdks.find_qt")
import(".filter")
import(".batchcmds")

-- check makensis, we need check some plugins
function _check_makensis(program)
    local tmpdir = os.tmpfile() .. ".dir"
    io.writefile(path.join(tmpdir, "test.nsis"), [[
        !include "MUI2.nsh"
        !include "WordFunc.nsh"
        !include "WinMessages.nsh"
        !include "FileFunc.nsh"
        !include "UAC.nsh"

        Name "test"
        OutFile "test.exe"

        Function .onInit
        FunctionEnd

        Section "test" InstallExeutable
        SectionEnd

        Function un.onInit
        FunctionEnd

        Section "Uninstall"
        SectionEnd]])
    os.runv(program, {"test.nsis"}, {curdir = tmpdir})
    os.tryrm(tmpdir)
end

-- safe directory removal for Windows
local function _safe_rmdir(dir)
    if not os.isdir(dir) then
        return true
    end
    
    -- Try multiple methods to remove directory
    local ok = false
    
    -- Method 1: Use os.tryrm first
    ok = os.tryrm(dir)
    if ok then
        print("Successfully removed directory using os.tryrm:", dir)
        return true
    end
    
    -- Method 2: Try Windows rmdir command
    if is_host("windows") then
        print("Trying Windows rmdir command for:", dir)
        local ok2 = try { function() 
            os.vrunv("cmd", {"/c", "rmdir", "/s", "/q", path.translate(dir)})
            return true
        end }
        if ok2 then
            print("Successfully removed directory using rmdir:", dir)
            return true
        end
    end
    
    -- Method 3: Try PowerShell Remove-Item
    if is_host("windows") then
        print("Trying PowerShell Remove-Item for:", dir)
        local ok3 = try { function()
            os.vrunv("powershell", {"-Command", "Remove-Item -Recurse -Force '" .. dir .. "'"})
            return true
        end }
        if ok3 then
            print("Successfully removed directory using PowerShell:", dir)
            return true
        end
    end
    
    return false
end

local function _log_deployed_files(deploy_dir)
    for _, file in ipairs(os.files(path.join(deploy_dir, "**"))) do
        print("  File:", file)
    end
    for _, dir in ipairs(os.dirs(path.join(deploy_dir, "**"))) do
        print("  Directory:", dir)
    end
end

-- get the makensis
function _get_makensis()

    -- enter the environments of nsis
    local oldenvs = packagenv.enter("nsis")

    -- find makensis
    local packages = {}
    local makensis = find_tool("makensis", {check = _check_makensis})
    if not makensis then
        table.join2(packages, install_packages("nsis"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not makensis then
        makensis = find_tool("makensis", {check = _check_makensis, force = true})
    end
    assert(makensis, "makensis not found!")
    return makensis, oldenvs
end

-- get windeployqt tool for Qt applications
function _get_windeployqt()
    local windeployqt = find_tool("windeployqt")
    if not windeployqt then
        -- Try to find it in Qt installation
        local qt = find_qt()
        if qt and qt.bindir then
            local windeployqt_path = path.join(qt.bindir, "windeployqt.exe")
            if os.isfile(windeployqt_path) then
                windeployqt = {program = windeployqt_path}
            end
        end
        
        if not windeployqt then
            return nil
        end
    end
    return windeployqt
end

-- get unique tag
function _get_unique_tag(content)
    return hash.strhash32(content)
end

-- translate the file path
function _translate_filepath(package, filepath)
    return filepath:replace(package:install_rootdir(), "$InstDir", {plain = true})
end

-- check if this is a Qt project
function _is_qt_project(package)
    -- Method 1: Check for Qt in package links
    local links = package:get("links")
    if links then
        for _, link in ipairs(links) do
            if link:lower():find("qt") then
                print("Qt project detected via link:", link)
                return true
            end
        end
    end

    -- Method 2: Check for Qt packages in requirements
    local requires = package:get("requires")
    if requires then
        for _, require in ipairs(requires) do
            if require:lower():find("qt") then
                print("Qt project detected via requirement:", require)
                return true
            end
        end
    end

    -- Method 3: Check source files for Qt headers/includes
    local srcfiles, _ = package:sourcefiles()
    for _, srcfile in ipairs(srcfiles or {}) do
        if srcfile:endswith(".cpp") or srcfile:endswith(".cc") or srcfile:endswith(".cxx") then
            if os.isfile(srcfile) then
                local content = io.readfile(srcfile)
                if content and (content:find("#include.*[Qq][Tt]") or 
                               content:find("#include.*<Q") or
                               content:find("QApplication") or
                               content:find("QWidget") or
                               content:find("QMainWindow")) then
                    print("Qt project detected via source file analysis:", srcfile)
                    return true
                end
            end
        end
    end

    print("No Qt dependencies detected")
    return false
end

-- find main executable path
function _find_main_executable(package)
    -- Try installation directory first
    local install_rootdir = package:install_rootdir()
    if install_rootdir then
        local bin_dir = path.join(install_rootdir, "bin")
        if os.isdir(bin_dir) then
            local exe_path = path.join(bin_dir, package:name() .. ".exe")
            if os.isfile(exe_path) then
                return exe_path
            end
        end
    end

    -- Try build directory
    local plat = os.host()
    local arch = os.arch()
    local mode = is_mode("debug") and "debug" or "release"
    
    local possible_paths = {
        path.join("build", plat, arch, mode, package:name() .. ".exe"),
        path.join("build", plat, arch, "release", package:name() .. ".exe"),
        path.join("build", plat, "release", package:name() .. ".exe"),
        path.join("build", "release", package:name() .. ".exe"),
        path.join("build", package:name() .. ".exe"),
    }
    
    for _, exe_path in ipairs(possible_paths) do
        if os.isfile(exe_path) then
            return path.absolute(exe_path)
        end
    end
    
    return nil
end

-- check if project uses QML
function _check_qml_usage(package)
    -- Method 1: Check for QML-related libraries in links
    local links = package:get("links") or {}
    for _, link in ipairs(links) do
        if link:lower():find("qml") or link:lower():find("quick") then
            print("QML usage detected via link:", link)
            return true
        end
    end

    -- Method 2: Check for .qml files in project
    local qml_files = os.files("**.qml")
    if qml_files and #qml_files > 0 then
        print("QML usage detected via .qml files:", #qml_files, "files found")
        return true
    end

    -- Method 3: Check source files for QML-related includes
    local srcfiles, _ = package:sourcefiles()
    for _, srcfile in ipairs(srcfiles or {}) do
        if srcfile:endswith(".cpp") or srcfile:endswith(".cc") or srcfile:endswith(".cxx") then
            if os.isfile(srcfile) then
                local content = io.readfile(srcfile)
                if content and (content:find("#include.*QQml") or 
                               content:find("#include.*QQuick") or
                               content:find("QQmlEngine") or
                               content:find("QQuickView")) then
                    print("QML usage detected via source file analysis:", srcfile)
                    return true
                end
            end
        end
    end

    return false
end

-- find project QML directory
function _find_project_qml_dir()
    local possible_qml_dirs = {"qml", "src/qml", "resources/qml", "assets/qml"}
    
    for _, qml_dir in ipairs(possible_qml_dirs) do
        if os.isdir(qml_dir) then
            print("Found project QML directory:", qml_dir)
            return path.absolute(qml_dir)
        end
    end
    
    return nil
end

-- deploy Qt dependencies using windeployqt and collect files
function _deploy_qt_dependencies(package, windeployqt)
    print("Deploying Qt dependencies using windeployqt...")
    
    local main_executable = _find_main_executable(package)
    if not main_executable then
        print("Error: Cannot find main executable for Qt deployment")
        return {}
    end
    
    print("Main executable found:", main_executable)
    
    -- Create a unique temporary deployment directory
    local deploy_dir = path.join(os.tmpdir(), package:name() .. "_qt_nsis_deploy_" .. os.time())
    print("Using temporary deployment directory:", deploy_dir)
    
    -- Remove existing directory if it exists
    if os.isdir(deploy_dir) then
        print("Removing existing temporary directory:", deploy_dir)
        _safe_rmdir(deploy_dir)
        -- Wait a bit to ensure directory is removed
        os.sleep(100)
    end
    
    -- Create the deployment directory
    print("Creating temporary directory:", deploy_dir)
    if not os.mkdir(deploy_dir) then
        print("Error: Failed to create deployment directory:", deploy_dir)
        return {}
    end
    
    -- Copy the main executable to deployment directory
    local deployed_exe = path.join(deploy_dir, path.filename(main_executable))
    print("Copying executable to deployment directory...")
    local copy_ok = try { function()
        os.cp(main_executable, deployed_exe)
        return true
    end }
    
    if not copy_ok then
        print("Error: Failed to copy executable to deployment directory")
        _safe_rmdir(deploy_dir)
        return {}
    end
    
    print("Copied executable to deployment directory:", deployed_exe)
    
    -- Get Qt SDK information
    local qt = find_qt()
    if not qt then
        print("Warning: Qt SDK not found")
        _safe_rmdir(deploy_dir)
        return {}
    end

    print("Qt SDK directory:", qt.sdkdir)
    print("Qt binary directory:", qt.bindir)
    print("Qt version:", qt.sdkver or "unknown")
    
    -- Set up environment variables for windeployqt
    local envs = {}
    if qt.bindir then
        envs.PATH = qt.bindir .. ";" .. (os.getenv("PATH") or "")
    end
    if qt.sdkdir then
        envs.QTDIR = qt.sdkdir
    end

    -- Build windeployqt arguments
    local args = {
        deployed_exe,
        "--verbose", "2",
        "--dir", deploy_dir,
        "--force"
    }
    
    -- Check if this is a QML project
    local uses_qml = _check_qml_usage(package)
    if uses_qml then
        local qml_dir = _find_project_qml_dir()
        if qml_dir then
            table.insert(args, "--qmldir")
            table.insert(args, qml_dir)
        else
            -- Use Qt's QML directory if available
            if qt.qmldir and os.isdir(qt.qmldir) then
                table.insert(args, "--qmldir")
                table.insert(args, qt.qmldir)
            else
                print("Warning: QML usage detected but no valid QML directory found")
            end
        end
    end

    print("Running windeployqt with command:")
    print("  Program:", windeployqt.program)
    print("  Args:", table.concat(args, " "))
    
    -- Execute windeployqt with error handling
    print("Executing windeployqt...")
    local ok, err = try { function()
        local result, err = os.iorunv(windeployqt.program, args, {envs = envs})
        if not result then
            print("windeployqt output error:", err or "unknown error")
            return false
        end
        return true
    end }
    
    if not ok then
        print("Error: windeployqt failed:", err or "unknown error")
        print("Falling back to manual deployment...")
        _safe_rmdir(deploy_dir)
        return {}
    end

    print("windeployqt completed successfully")
    -- Log deployed files
    _log_deployed_files(deploy_dir)
    
    -- Collect all deployed files and generate NSIS commands
    local nsis_commands = {}
    local function collect_and_generate(dir, base_dir, relative_path)
        base_dir = base_dir or dir
        relative_path = relative_path or ""
        
        local files = os.files(path.join(dir, "*"))
        local dirs = os.dirs(path.join(dir, "*"))
        
        -- Add files in current directory
        if #files > 0 then
            local nsis_outpath = relative_path ~= "" and ("$InstDir\\" .. relative_path) or "$InstDir"
            table.insert(nsis_commands, string.format('SetOutPath "%s"', nsis_outpath))
            
            for _, file in ipairs(files) do
                local filename = path.filename(file)
                -- Skip the copied executable to avoid conflicts
                if filename ~= path.filename(main_executable) then
                    table.insert(nsis_commands, string.format('File "%s"', file))
                end
            end
        end
        
        -- Recursively process subdirectories
        for _, subdir in ipairs(dirs) do
            local subdir_name = path.filename(subdir)
            local new_relative_path = relative_path ~= "" and (relative_path .. "\\" .. subdir_name) or subdir_name
            collect_and_generate(subdir, base_dir, new_relative_path)
        end
    end
    
    collect_and_generate(deploy_dir)
    
    -- Create qt.conf to ensure plugins are found
    local qt_conf_content = [[
[Paths]
Plugins = .
]]
    local qt_conf_file = os.tmpfile() .. ".conf"
    io.writefile(qt_conf_file, qt_conf_content)
    table.insert(nsis_commands, 'SetOutPath "$InstDir\\bin"')
    table.insert(nsis_commands, string.format('File "/oname=qt.conf" "%s"', qt_conf_file))
    
    print("Generated", #nsis_commands, "NSIS commands for Qt deployment")
    
    -- Clean up temporary deployment directory
    _safe_rmdir(deploy_dir)
    
    return nsis_commands
end

-- get Qt deployment commands for Windows
function _get_qt_deployment_commands(package)
    local qt = find_qt()
    if not qt then
        print("Warning: Qt SDK not found, cannot deploy Qt dependencies")
        return {}
    end

    -- Try to use windeployqt first
    local windeployqt = _get_windeployqt()
    if windeployqt then
        local nsis_commands = _deploy_qt_dependencies(package, windeployqt)
        if #nsis_commands > 0 then
            return nsis_commands
        end
        print("windeployqt failed, falling back to manual deployment")
    else
        print("windeployqt not found, using manual deployment")
    end
    -- Manual Qt deployment fallback
    local qt_version = qt.sdkver or "5.15.3"
    local is_qt6 = qt_version:startswith("6")
    local commands = {}
    -- Deploy Qt core libraries
    local qt_libs = {}
    if is_qt6 then
        qt_libs = {"Qt6Core.dll", "Qt6Gui.dll", "Qt6Widgets.dll"}
    else
        qt_libs = {"Qt5Core.dll", "Qt5Gui.dll", "Qt5Widgets.dll"}
    end
    
    -- Add additional libraries based on links
    local links = package:get("links") or {}
    for _, link in ipairs(links) do
        local link_lower = link:lower()
        if is_qt6 then
            if link_lower:find("network") then table.insert(qt_libs, "Qt6Network.dll") end
            if link_lower:find("sql") then table.insert(qt_libs, "Qt6Sql.dll") end
            if link_lower:find("xml") then table.insert(qt_libs, "Qt6Xml.dll") end
            if link_lower:find("printsupport") then table.insert(qt_libs, "Qt6PrintSupport.dll") end
            if link_lower:find("multimedia") then table.insert(qt_libs, "Qt6Multimedia.dll") end
            if link_lower:find("opengl") then table.insert(qt_libs, "Qt6OpenGL.dll") end
            if link_lower:find("svg") then table.insert(qt_libs, "Qt6Svg.dll") end
            if link_lower:find("quick") then 
                table.insert(qt_libs, "Qt6Quick.dll")
                table.insert(qt_libs, "Qt6Qml.dll")
            end
        else
            if link_lower:find("network") then table.insert(qt_libs, "Qt5Network.dll") end
            if link_lower:find("sql") then table.insert(qt_libs, "Qt5Sql.dll") end
            if link_lower:find("xml") then table.insert(qt_libs, "Qt5Xml.dll") end
            if link_lower:find("printsupport") then table.insert(qt_libs, "Qt5PrintSupport.dll") end
            if link_lower:find("multimedia") then table.insert(qt_libs, "Qt5Multimedia.dll") end
            if link_lower:find("opengl") then table.insert(qt_libs, "Qt5OpenGL.dll") end
            if link_lower:find("svg") then table.insert(qt_libs, "Qt5Svg.dll") end
            if link_lower:find("quick") then 
                table.insert(qt_libs, "Qt5Quick.dll")
                table.insert(qt_libs, "Qt5Qml.dll")
            end
        end
    end
    
    -- Deploy DLLs
    table.insert(commands, 'SetOutPath "$InstDir\\bin"')
    for _, lib in ipairs(qt_libs) do
        local lib_path = path.join(qt.bindir or qt.libdir, lib)
        if os.isfile(lib_path) then
            table.insert(commands, string.format('File "%s"', lib_path))
        end
    end
    
    -- Deploy Qt plugins (CRITICAL for Qt applications)
    if qt.pluginsdir and os.isdir(qt.pluginsdir) then
        local plugin_categories = {"platforms", "imageformats", "iconengines", "styles"}
        for _, category in ipairs(plugin_categories) do
            local plugin_dir = path.join(qt.pluginsdir, category)
            if os.isdir(plugin_dir) then
                table.insert(commands, string.format('SetOutPath "$InstDir\\%s"', category))
                local plugin_files = os.files(path.join(plugin_dir, "*.dll"))
                for _, plugin_file in ipairs(plugin_files) do
                    table.insert(commands, string.format('File "%s"', plugin_file))
                end
            end
        end
    else
        -- Try alternative plugin location
        local alt_plugins_dir = path.join(qt.sdkdir, "plugins")
        if os.isdir(alt_plugins_dir) then
            local plugin_categories = {"platforms", "imageformats", "iconengines", "styles"}
            for _, category in ipairs(plugin_categories) do
                local plugin_dir = path.join(alt_plugins_dir, category)
                if os.isdir(plugin_dir) then
                    table.insert(commands, string.format('SetOutPath "$InstDir\\%s"', category))
                    local plugin_files = os.files(path.join(plugin_dir, "*.dll"))
                    for _, plugin_file in ipairs(plugin_files) do
                        table.insert(commands, string.format('File "%s"', plugin_file))
                    end
                end
            end
        end
    end
    
    -- Create qt.conf to specify plugin paths
    local qt_conf_content = [[
[Paths]
Plugins = .
]]
    local qt_conf_file = os.tmpfile() .. ".conf"
    io.writefile(qt_conf_file, qt_conf_content)
    table.insert(commands, 'SetOutPath "$InstDir\\bin"')
    table.insert(commands, string.format('File "/oname=qt.conf" "%s"', qt_conf_file))
    
    return commands
end

-- get command string
function _get_command_strings(package, cmd, opt)
    opt = table.join(cmd.opt or {}, opt)
    local result = {}
    local kind = cmd.kind
    if kind == "cp" then
        -- https://nsis.sourceforge.io/Reference/File
        local srcfiles = os.files(cmd.srcpath)
        for _, srcfile in ipairs(srcfiles) do
            -- the destination is directory? append the filename
            local dstfile = _translate_filepath(package, cmd.dstpath)
            if #srcfiles > 1 or path.islastsep(dstfile) then
                if opt.rootdir then
                    dstfile = path.join(dstfile, path.relative(srcfile, opt.rootdir))
                else
                    dstfile = path.join(dstfile, path.filename(srcfile))
                end
            end
            srcfile = path.normalize(srcfile)
            local dstname = path.filename(dstfile)
            local dstdir = path.normalize(path.directory(dstfile))
            table.insert(result, string.format("SetOutPath \"%s\"", dstdir))
            table.insert(result, string.format("File \"/oname=%s\" \"%s\"", dstname, srcfile))
        end
    elseif kind == "rm" then
        local filepath = _translate_filepath(package, cmd.filepath)
        table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMFileIfExists" or "unRMFileIfExists", filepath))
        if opt.emptydirs then
            table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMEmptyParentDirs" or "unRMEmptyParentDirs", filepath))
        end
    elseif kind == "rmdir" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMDirIfExists" or "unRMDirIfExists", dir))
        if opt.emptydirs then
            table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMEmptyParentDirs" or "unRMEmptyParentDirs", dir))
        end
    elseif kind == "mv" then
        local srcpath = _translate_filepath(package, cmd.srcpath)
        local dstpath = _translate_filepath(package, cmd.dstpath)
        table.insert(result, string.format("Rename \"%s\" \"%s\"", srcpath, dstpath))
    elseif kind == "cd" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(result, string.format("SetOutPath \"%s\"", dir))
    elseif kind == "mkdir" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(result, string.format("CreateDirectory \"%s\"", dir))
    elseif kind == "nsis" then
        table.insert(result, cmd.rawstr)
    end
    return result
end

-- get commands string
function _get_commands_string(package, cmds, opt)
    local cmdstrs = {}
    for _, cmd in ipairs(cmds) do
        table.join2(cmdstrs, _get_command_strings(package, cmd, opt))
    end
    return table.concat(cmdstrs, "\n  ")
end

-- get install commands of component
function _get_component_installcmds(component)
    return _get_commands_string(component, batchcmds.get_installcmds(component):cmds(), {install = true})
end

-- get uninstall commands of component
function _get_component_uninstallcmds(component)
    return _get_commands_string(component, batchcmds.get_uninstallcmds(component):cmds(), {install = false})
end

-- get install commands
function _get_installcmds(package)
    local cmdstrs = _get_commands_string(package, batchcmds.get_installcmds(package):cmds(), {install = true})
    
    -- Add Qt deployment commands if this is a Qt project
    if _is_qt_project(package) then
        print("Adding Qt deployment commands to installer")
        local qt_commands = _get_qt_deployment_commands(package)
        if #qt_commands > 0 then
            cmdstrs = cmdstrs .. "\n  ; Qt deployment commands\n  " .. table.concat(qt_commands, "\n  ")
        end
    end
    
    return cmdstrs
end

-- get uninstall commands
function _get_uninstallcmds(package)
    local cmdstrs = _get_commands_string(package, batchcmds.get_uninstallcmds(package):cmds(), {install = false})
    
    -- Add Qt cleanup commands if this is a Qt project
    if _is_qt_project(package) then
        print("Adding Qt cleanup commands to uninstaller")
        local qt_version = "unknown"
        local qt = find_qt()
        if qt then
            qt_version = qt.sdkver or "5.15.3"
        end
        local is_qt6 = qt_version:startswith("6")
        
        local qt_cleanup_commands = {
            '${unRMDirIfExists} "$InstDir\\platforms"',
            '${unRMDirIfExists} "$InstDir\\imageformats"',
            '${unRMDirIfExists} "$InstDir\\iconengines"',
            '${unRMDirIfExists} "$InstDir\\styles"',
            '${unRMFileIfExists} "$InstDir\\bin\\qt.conf"',
        }
        
        -- Add version-specific cleanup
        if is_qt6 then
            table.insert(qt_cleanup_commands, '${unRMFileIfExists} "$InstDir\\bin\\Qt6Core.dll"')
            table.insert(qt_cleanup_commands, '${unRMFileIfExists} "$InstDir\\bin\\Qt6Gui.dll"')
            table.insert(qt_cleanup_commands, '${unRMFileIfExists} "$InstDir\\bin\\Qt6Widgets.dll"')
            table.insert(qt_cleanup_commands, '${unRMFileIfExists} "$InstDir\\bin\\Qt6Network.dll"')
            table.insert(qt_cleanup_commands, '${unRMFileIfExists} "$InstDir\\bin\\Qt6Sql.dll"')
        else
            table.insert(qt_cleanup_commands, '${unRMFileIfExists} "$InstDir\\bin\\Qt5Core.dll"')
            table.insert(qt_cleanup_commands, '${unRMFileIfExists} "$InstDir\\bin\\Qt5Gui.dll"')
            table.insert(qt_cleanup_commands, '${unRMFileIfExists} "$InstDir\\bin\\Qt5Widgets.dll"')
            table.insert(qt_cleanup_commands, '${unRMFileIfExists} "$InstDir\\bin\\Qt5Network.dll"')
            table.insert(qt_cleanup_commands, '${unRMFileIfExists} "$InstDir\\bin\\Qt5Sql.dll"')
        end
        
        cmdstrs = cmdstrs .. "\n  ; Qt cleanup commands\n  " .. table.concat(qt_cleanup_commands, "\n  ")
    end
    
    return cmdstrs
end

-- get value and filter it
function _get_filter_value(package, name)
    local value = package:get(name)
    if type(value) == "string" then
        value = filter.handle(value, package)
    end
    return value
end

-- get target file path
function _get_target_filepath(package)
    local targetfile
    for _, target in ipairs(package:targets()) do
        if target:is_binary() then
            targetfile = target:targetfile()
            break
        end
    end
    if targetfile then
        return _translate_filepath(package, path.join(package:bindir(), path.filename(targetfile)))
    end
end

-- get specvars
function _get_specvars(package)
    local specvars = table.clone(package:specvars())
    specvars.PACKAGE_WORKDIR = path.absolute(os.projectdir())
    specvars.PACKAGE_BINDIR = _translate_filepath(package, package:bindir())
    specvars.PACKAGE_OUTPUTFILE = path.absolute(package:outputfile())
    if specvars.PACKAGE_VERSION_BUILD then
        -- @see https://github.com/xmake-io/xmake/issues/5306
        specvars.PACKAGE_VERSION_BUILD = specvars.PACKAGE_VERSION_BUILD:gsub(" ", "_")
    end
    specvars.PACKAGE_INSTALLCMDS = function ()
        return _get_installcmds(package)
    end
    specvars.PACKAGE_UNINSTALLCMDS = function ()
        return _get_uninstallcmds(package)
    end
    specvars.PACKAGE_NSIS_DISPLAY_ICON = function ()
        local iconpath = _get_filter_value(package, "nsis_displayicon")
        if iconpath then
            iconpath = path.join(package:installdir(), iconpath)
        end
        if not iconpath then
            iconpath = _get_target_filepath(package) or ""
        end
        return _translate_filepath(package, iconpath)
    end

    -- install sections
    local install_sections = {}
    local install_descs = {}
    local install_description_texts = {}
    for name, component in table.orderpairs(package:components()) do
        local installcmds = _get_component_installcmds(component)
        if installcmds and #installcmds > 0 then
            local tag = "Install" .. name
            table.insert(install_sections, string.format('Section%s "%s" %s', component:get("default") == false and " /o" or "", component:title(), tag))
            table.insert(install_sections, installcmds)
            table.insert(install_sections, "SectionEnd")
            table.insert(install_descs, string.format('LangString DESC_%s ${LANG_ENGLISH} "%s"', tag, component:description() or ""))
            table.insert(install_description_texts, string.format('!insertmacro MUI_DESCRIPTION_TEXT ${%s} $(DESC_%s)', tag, tag))
        end
        local uninstallcmds = _get_component_uninstallcmds(component)
        if uninstallcmds and #uninstallcmds > 0 then
            local tag = "Uninstall" .. name
            table.insert(install_sections, string.format('Section "un.%s" %s', component:title(), tag))
            table.insert(install_sections, uninstallcmds)
            table.insert(install_sections, "SectionEnd")
        end
    end
    specvars.PACKAGE_NSIS_INSTALL_SECTIONS = table.concat(install_sections, "\n  ")
    specvars.PACKAGE_NSIS_INSTALL_DESCS = table.concat(install_descs, "\n  ")
    specvars.PACKAGE_NSIS_INSTALL_DESCRIPTION_TEXTS = table.concat(install_description_texts, "\n  ")
    return specvars
end

-- pack nsis package
function _pack_nsis(makensis, package)

    -- install the initial specfile
    local specfile = path.join(package:builddir(), package:basename() .. ".nsi")
    if not os.isfile(specfile) then
        local specfile_template = package:get("specfile") or path.join(os.programdir(), "scripts", "xpack", "nsis", "makensis.nsi")
        os.cp(specfile_template, specfile)
    end

    -- replace variables in specfile,
    -- and we need to avoid `attempt to yield across a C-call boundary` in io.gsub
    local specvars = _get_specvars(package)
    local pattern = package:extraconf("specfile", "pattern") or "%${([^\n]-)}"
    local specvars_names = {}
    local specvars_values = {}
    io.gsub(specfile, "(" .. pattern .. ")", function(_, name)
        table.insert(specvars_names, name)
    end, {encoding = "ansi"})
    for _, name in ipairs(specvars_names) do
        name = name:trim()
        if specvars_values[name] == nil then
            local value = specvars[name]
            if type(value) == "function" then
                value = value()
            end
            if value ~= nil then
                dprint("  > replace %s -> %s", name, value)
            end
            if type(value) == "table" then
                dprint("invalid variable value", value)
            end
            specvars_values[name] = value
        end
    end
    io.gsub(specfile, "(" .. pattern .. ")", function(_, name)
        name = name:trim()
        return specvars_values[name]
    end, {encoding = "ansi"})

    -- make package
    os.vrunv(makensis, {specfile})
end

function main(package)

    -- only for windows
    if not is_host("windows") then
        return
    end

    cprint("packing %s", package:outputfile())

    -- check if this is a Qt project
    local is_qt = _is_qt_project(package)
    if is_qt then
        cprint("Detected Qt project - using windeployqt for proper dependency deployment")
        
        -- Check for windeployqt availability
        local windeployqt = _get_windeployqt()
    end

    -- get makensis
    local makensis, oldenvs = _get_makensis()

    -- pack nsis package
    _pack_nsis(makensis.program, package)

    -- done
    os.setenvs(oldenvs)
end