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

-- get the create-dmg tool
function _get_create_dmg()
    local create_dmg = find_tool("create-dmg")
    if not create_dmg then
        return nil
    end
    return create_dmg
end

-- get macdeployqt tool for Qt applications
function _get_macdeployqt()
    local macdeployqt = find_tool("macdeployqt")
    if not macdeployqt then
        -- Try to find it in Qt installation
        local qt = find_qt()
        if qt and qt.bindir then
            local macdeployqt_path = path.join(qt.bindir, "macdeployqt")
            if os.isfile(macdeployqt_path) then
                macdeployqt = {program = macdeployqt_path}
            end
        end
        
        if not macdeployqt then
            return nil
        end
    end
    return macdeployqt
end

-- detect if this is a Qt project
function _is_qt_project(package)
    -- Method 1: Check for Qt libraries in links
    local links = package:get("links")
    if links then
        for _, link in ipairs(links) do
            if link:lower():find("qt") then
                return true
            end
        end
    end

    -- Method 2: Check executable for Qt dependencies using otool
    local app_source, _ = _find_app_bundle(package)
    if app_source then
        local macos_dir = path.join(app_source, "Contents", "MacOS")
        if os.isdir(macos_dir) then
            local executables = os.files(path.join(macos_dir, "*"))
            for _, executable in ipairs(executables) do
                if os.isfile(executable) then
                    local otool_output = os.iorunv("otool", {"-L", executable})
                    if otool_output then
                        -- Check for Qt frameworks in otool output
                        if otool_output:lower():find("qt") or 
                           otool_output:find("QtCore") or 
                           otool_output:find("QtGui") or
                           otool_output:find("QtWidgets") then
                            return true
                        end
                    end
                end
            end
        end
    end

    -- Method 3: Check source files for Qt headers/includes
    local srcfiles, _ = package:sourcefiles()
    for _, srcfile in ipairs(srcfiles or {}) do
        if srcfile:endswith(".cpp") or srcfile:endswith(".cc") or srcfile:endswith(".cxx") or srcfile:endswith(".mm") then
            if os.isfile(srcfile) then
                local content = io.readfile(srcfile)
                if content and (content:find("#include.*[Qq][Tt]") or 
                               content:find("#include.*<Q") or
                               content:find("QApplication") or
                               content:find("QWidget") or
                               content:find("QMainWindow")) then
                    return true
                end
            end
        end
    end

    return false
end

function _check_qml_usage(package, app_source)
    -- Method 1: Check for QML-related libraries in links
    local links = package:get("links")
    if links then
        for _, link in ipairs(links) do
            if link:lower():find("qml") or link:lower():find("quick") then
                return true
            end
        end
    end

    -- Method 2: Check executable for QML/Quick dependencies
    local macos_dir = path.join(app_source, "Contents", "MacOS")
    if os.isdir(macos_dir) then
        local executables = os.files(path.join(macos_dir, "*"))
        for _, executable in ipairs(executables) do
            if os.isfile(executable) then
                local otool_output = os.iorunv("otool", {"-L", executable})
                if otool_output then
                    if otool_output:find("QtQml") or otool_output:find("QtQuick") then
                        return true
                    end
                end
            end
        end
    end

    -- Method 3: Check for .qml files in project
    local qml_files = os.files("**.qml")
    if qml_files and #qml_files > 0 then
        return true
    end

    -- Method 4: Check source files for QML-related includes
    local srcfiles, _ = package:sourcefiles()
    for _, srcfile in ipairs(srcfiles or {}) do
        if srcfile:endswith(".cpp") or srcfile:endswith(".cc") or srcfile:endswith(".cxx") or srcfile:endswith(".mm") then
            if os.isfile(srcfile) then
                local content = io.readfile(srcfile)
                if content and (content:find("#include.*QQml") or 
                               content:find("#include.*QQuick") or
                               content:find("QQmlEngine") or
                               content:find("QQuickView")) then
                    return true
                end
            end
        end
    end

    return false
end

function _find_valid_qml_dir(qt)
    local possible_qml_dirs = {}
    
    -- Standard QML directory locations
    if qt.sdkdir then
        table.insert(possible_qml_dirs, path.join(qt.sdkdir, "qml"))
        table.insert(possible_qml_dirs, path.join(qt.sdkdir, "lib", "qml"))
        table.insert(possible_qml_dirs, path.join(qt.sdkdir, "share", "qt6", "qml"))
    end
    
    -- Qt-specific qmldir if available
    if qt.qmldir then
        table.insert(possible_qml_dirs, qt.qmldir)
    end
    
    -- Project-specific QML directories
    table.insert(possible_qml_dirs, "qml")
    table.insert(possible_qml_dirs, "src/qml")
    table.insert(possible_qml_dirs, "resources/qml")
    
    for _, qml_dir in ipairs(possible_qml_dirs) do
        if os.isdir(qml_dir) then
            return qml_dir
        end
    end
    
    -- If no existing QML directory found, create a temporary empty one
    local temp_qml_dir = path.join(os.tmpdir(), "empty_qml")
    if not os.isdir(temp_qml_dir) then
        os.mkdir(temp_qml_dir)
    end
    
    return temp_qml_dir
end

-- deploy Qt dependencies using macdeployqt
function _deploy_qt_dependencies(package, app_source, macdeployqt)

    -- Get Qt SDK information
    local qt = find_qt()
    if not qt then
        return false
    end

    local qt_version = qt.sdkver or "5.15.3"

    -- Verify the .app bundle structure
    local contents_dir = path.join(app_source, "Contents")
    local macos_dir = path.join(contents_dir, "MacOS")
    local info_plist = path.join(contents_dir, "Info.plist")

    if not os.isdir(contents_dir) then
        return false
    end
    if not os.isdir(macos_dir) then
        return false
    end
    if not os.isfile(info_plist) then
        return false
    end

    -- Find the main executable
    local executables = os.files(path.join(macos_dir, "*"))
    local main_executable = nil
    for _, exe in ipairs(executables) do
        if os.isfile(exe) and not exe:endswith(".dylib") then
            main_executable = exe
            break
        end
    end

    if not main_executable then
        return false
    end

    -- Set up environment variables for macdeployqt
    local envs = {}
    
    -- Set Qt-related environment variables
    if qt.bindir then
        envs.PATH = qt.bindir .. ":" .. (os.getenv("PATH") or "")
    end
    if qt.libdir then
        envs.DYLD_LIBRARY_PATH = qt.libdir .. ":" .. (os.getenv("DYLD_LIBRARY_PATH") or "")
    end
    if qt.sdkdir then
        envs.QTDIR = qt.sdkdir
    end

    -- Build macdeployqt command arguments
    local args = { app_source }
    
    -- Add verbose output
    table.insert(args, "-verbose=2")
    
    -- Check if this project actually uses QML before adding qmldir
    local uses_qml = _check_qml_usage(package, app_source)
    
    if uses_qml then
        -- Find a valid QML directory
        local qml_dir = _find_valid_qml_dir(qt)
        if qml_dir then
            table.insert(args, "-qmldir")
            table.insert(args, qml_dir)
        else
            print("Warning: QML usage detected but no valid QML directory found")
        end
    else
        print("No QML usage detected, skipping -qmldir option")
    end

    -- Execute macdeployqt
    local ok, err = os.iorunv(macdeployqt.program, args, {envs = envs})
    if not ok then
        return false
    end

    -- Verify results: check for bundled Qt frameworks
    local frameworks_dir = path.join(contents_dir, "Frameworks")
    local success = false
    
    if os.isdir(frameworks_dir) then
        local qt_frameworks = os.dirs(path.join(frameworks_dir, "Qt*.framework"))
        if #qt_frameworks > 0 then
            success = true
        else
            print("Warning: No Qt frameworks found in Frameworks directory")
        end
        
        -- Show all bundled frameworks
        local all_frameworks = os.dirs(path.join(frameworks_dir, "*.framework"))
    else
        print("Warning: Frameworks directory not created:", frameworks_dir)
    end

    -- Check for Qt plugins
    local plugins_dir = path.join(contents_dir, "PlugIns")
    if os.isdir(plugins_dir) then
        local qt_plugins = os.dirs(path.join(plugins_dir, "*"))
        for _, plugin_dir in ipairs(qt_plugins) do
            local plugin_files = os.files(path.join(plugin_dir, "*"))
        end
        if #qt_plugins > 0 then
            success = true
        end
    else
        print("Warning: PlugIns directory not created:", plugins_dir)
    end

    -- Final verification: check executable dependencies
    if success then
        local otool_output = os.iorunv("otool", {"-L", main_executable})
        if otool_output then
            local external_qt_refs = {}
            for line in otool_output:gmatch("[^\r\n]+") do
                -- Look for Qt framework references that are not in the bundle
                local qt_ref = line:match("(%S*Qt%w+%.framework[^%s]*)")
                if qt_ref and not qt_ref:find("@executable_path") and not qt_ref:find("@rpath") then
                    table.insert(external_qt_refs, qt_ref)
                end
            end
            
            if #external_qt_refs > 0 then
                -- Don't fail here as some external references might be acceptable
            else
                print("Qt dependency verification successful - all Qt references are bundled")
            end
        end
    end

    return success
end

-- find existing .app bundle in the build directory
function _find_app_bundle(package)
    -- Get current build information
    local plat = os.host()  -- Get current platform (macosx, linux, windows, etc.)
    local arch = os.arch()  -- Get current architecture (arm64, x86_64, etc.)
    local mode = is_mode("debug") and "debug" or "release"  -- Get build mode
    local app_name = package:get("title") or package:name()
    local appbundle_name = app_name .. ".app"
    
    -- Build platform-specific path patterns
    local platform_paths = {
        -- Standard xmake platform directory structure
        path.join("build", plat, arch, mode),
        path.join("build", plat, arch, "release"),
        path.join("build", plat, arch, "debug"),
        path.join("build", plat, "release"),
        path.join("build", plat, "debug"),
        path.join("build", plat, arch),
        path.join("build", plat),
        
        -- Some variants
        path.join("build", mode),
        path.join("build", "release"),
        path.join("build", "debug"),
        
        -- xpack output directory
        path.join("build", "xpack"),
        
        -- Root build directory
        "build",
        
        -- Current directory
        "."
    }
    
    -- Possible .app locations
    local possible_locations = {}
    
    -- Generate possible .app locations for each platform path
    for _, base_path in ipairs(platform_paths) do
        table.insert(possible_locations, path.join(base_path, appbundle_name))
        -- Also check bin subdirectory
        table.insert(possible_locations, path.join(base_path, "bin", appbundle_name))
    end
    
    for i, location in ipairs(possible_locations) do
        local abs_location = path.absolute(location)
        if os.isdir(abs_location) then
            -- Verify this is actually a .app bundle
            local info_plist = path.join(abs_location, "Contents", "Info.plist")
            local macos_dir = path.join(abs_location, "Contents", "MacOS")
            if os.isfile(info_plist) and os.isdir(macos_dir) then
                return abs_location, appbundle_name
            else
                print("      Invalid .app structure")
            end
        end
    end
    return nil, nil
end

-- find background image
function _find_background_image(package)
    local bg_paths = {
        "bg.svg",
        "background.svg",
        "dmg_background.svg",
        "assets/bg.svg",
        "assets/background.svg",
        "resources/bg.svg",
        "resources/background.svg"
    }
    
    -- also check if user specified a custom background
    local custom_bg = package:get("dmg_background")
    if custom_bg then
        table.insert(bg_paths, 1, custom_bg)
    end
    
    for _, bg_path in ipairs(bg_paths) do
        if os.isfile(bg_path) then
            ab_bg_path = path.absolute(bg_path)
            print("Found background image at:", ab_bg_path)
            return ab_bg_path
        end
    end
    return nil
end

-- get dmg output file path
function _get_dmg_file(package)
    local filename = string.format("%s-%s.dmg", package:name(), package:version())
    local output_dir = path.directory(package:outputfile() or "build")
    local dmg_path = path.absolute(path.join(output_dir, filename))
    
    -- ensure single .dmg extension
    dmg_path = dmg_path:gsub("%.dmg+$", ".dmg")
    return dmg_path
end

-- create dmg staging directory
function _create_staging_dir(package, app_source, appbundle_name, bg_image)
    local staging_dir = path.join(os.tmpdir(), package:name() .. "_dmg_staging")
    -- clean and create staging directory
    if os.isdir(staging_dir) then
        os.vrunv("rm", {"-rf", staging_dir})
    end
    os.mkdir(staging_dir)
    -- copy .app bundle to staging
    local app_dest = path.join(staging_dir, appbundle_name)
    os.vcp(app_source, app_dest)
    if not os.isdir(app_dest) then
        return nil
    end
    
    -- copy background image if exists
    if bg_image then
        local bg_dest = path.join(staging_dir, path.filename(bg_image))
        os.vcp(bg_image, bg_dest)
        if not os.isfile(bg_dest) then
            print("Warning: Failed to copy background image")
        end
    end
    
    return staging_dir
end

-- create dmg using create-dmg
function _create_dmg_with_create_dmg(create_dmg, package, staging_dir, dmg_file, appbundle_name, bg_image)
    local config = {
        title = (package:get("title") or package:name() .. " Installer"),
        window_pos = package:get("dmg_window_pos") or "400,200",
        window_size = package:get("dmg_window_size") or "660,400", 
        icon_size = package:get("dmg_icon_size") or 100,
        app_position = package:get("dmg_icon_position") or "160,185",
        apps_link_position = package:get("dmg_applications_pos") or "500,185"
    }
    -- parse window position
    local window_pos_x, window_pos_y = config.window_pos:match("(%d+),(%d+)")
    window_pos_x = window_pos_x or "400"
    window_pos_y = window_pos_y or "200"
    
    -- parse window size
    local window_w, window_h = config.window_size:match("(%d+),(%d+)")
    if not window_w then
        window_w, window_h = config.window_size:match("(%d+)x(%d+)")
    end
    window_w = window_w or "660"
    window_h = window_h or "400"
    
    -- parse app position
    local app_x, app_y = config.app_position:match("(%d+),(%d+)")
    app_x = app_x or "160"
    app_y = app_y or "185"
    
    -- parse Applications link position
    local apps_x, apps_y = config.apps_link_position:match("(%d+),(%d+)")
    apps_x = apps_x or "500"
    apps_y = apps_y or "185"
    
    -- build create-dmg arguments following the reference format
    local args = {
        "--volname", config.title,
        "--window-pos", window_pos_x, window_pos_y,
        "--window-size", window_w, window_h,
        "--icon-size", tostring(config.icon_size),
        "--icon", appbundle_name, app_x, app_y,
        "--hide-extension", appbundle_name,
        "--app-drop-link", apps_x, apps_y
    }
    if bg_image then
        local bg_name = path.filename(bg_image)
        -- insert background after volname
        table.insert(args, 3, "--background")
        table.insert(args, 4, bg_name)
    end
    -- add output file and source directory at the end
    table.insert(args, dmg_file)
    table.insert(args, staging_dir)
    -- ensure output directory exists
    os.vrunv("mkdir", {"-p", path.directory(dmg_file)})
    
    -- remove existing dmg file if exists
    os.vrunv("rm", {"-f", dmg_file})
    
    -- run create-dmg
    local ok, errors = os.iorunv(create_dmg.program, args)
    
    if ok then
        return true
    else
        if errors then
            print("Error output:", errors)
        end
        return false
    end
end

-- verify dmg file
function _verify_dmg(dmg_file)
    if not os.isfile(dmg_file) then
        return false
    end    
    return true
end

-- main packing function
function _pack_dmg(package)
    local is_qt = _is_qt_project(package)
    if is_qt then
        print("Detected Qt project - will use Qt-specific packaging")
    end
    
    -- find required tools
    local create_dmg = _get_create_dmg()
    if not create_dmg then
        return false
    end
    
    -- find existing .app bundle
    local app_source, appbundle_name = _find_app_bundle(package)
    if not app_source then
        return false
    end
    
    -- handle Qt dependencies if this is a Qt project
    if is_qt then
        local macdeployqt = _get_macdeployqt()
        if macdeployqt then
            local qt_success = _deploy_qt_dependencies(package, app_source, macdeployqt)
        else
            print("Warning: macdeployqt not available, Qt dependencies may not be properly bundled")
        end
    end
    
    -- find background image (optional)
    local bg_image = _find_background_image(package)
    
    -- get output dmg path
    local dmg_file = package:outputfile() or _get_dmg_file(package)
    dmg_file = dmg_file:gsub("%.dmg+$", ".dmg")  -- clean up extension
    -- create staging directory
    local staging_dir = _create_staging_dir(package, app_source, appbundle_name, bg_image)
    if not staging_dir then
        return false
    end
    
    -- create dmg
    local success = _create_dmg_with_create_dmg(create_dmg, package, staging_dir, dmg_file, appbundle_name, bg_image)
    
    if success then
        -- verify the result
        success = _verify_dmg(dmg_file)
    end
    
    -- cleanup staging directory
    os.tryrm(staging_dir)
    return success
end

-- main function 
function main(package)
    -- only for macOS
    if not is_host("macosx") then
        print("DMG packaging is only supported on macOS")
        return
    end
    
    local dmg_file = package:outputfile() or _get_dmg_file(package)
    dmg_file = dmg_file:gsub("%.dmg+$", ".dmg")
    
    cprint("packing %s", dmg_file)
    
    local success = _pack_dmg(package)
    if success then
        print("Final DMG file:", dmg_file)
    else
        os.exit(1)
    end
end