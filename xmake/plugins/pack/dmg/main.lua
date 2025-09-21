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

-- get the create-dmg tool
function _get_create_dmg()
    return assert(find_tool("create-dmg"), "create-dmg not found!")
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
    -- ensure output directory
    os.vrunv("mkdir", {"-p", path.directory(dmg_file)})
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
    -- find required tools
    local create_dmg = _get_create_dmg()
    -- find existing .app bundle
    local app_source, appbundle_name = _find_app_bundle(package)
    if not app_source then
        return false
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
    _pack_dmg(package)
end