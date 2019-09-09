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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.project.config")
import("core.project.target")

-- make link for framework
function _link(framework, major)
    if major and framework:startswith("Qt") then
        local debug_suffix = "_debug"
        if is_plat("windows") then
            debug_suffix = "d"
        elseif is_plat("android") then
            debug_suffix = ""
        end
        framework = "Qt" .. major .. framework:sub(3) .. (is_mode("debug") and debug_suffix or "")
    end
    return framework
end

-- find the static links from the given qt link directories, e.g. libqt*.a
function _find_static_links(linkdirs, libpattern)
    local links = {}
    local debug_suffix = "_debug"
    if is_plat("windows") then
        debug_suffix = "d"
    elseif is_plat("android") then
        debug_suffix = ""
    end
    for _, linkdir in ipairs(linkdirs) do
        for _, libpath in ipairs(os.files(path.join(linkdir, libpattern))) do
            local basename = path.basename(libpath)
            if (is_mode("debug") and basename:endswith(debug_suffix)) or (not is_mode("debug") and not basename:endswith(debug_suffix)) then
                table.insert(links, target.linkname(path.filename(libpath)))
            end
        end
    end
    return links
end

-- add plugins
function _add_plugins(target, plugins)
    for name, plugin in pairs(plugins) do
        target:values_add("qt.plugins", name)
        if plugin.links then
            target:values_add("qt.links", unpack(table.wrap(plugin.links)))
        end
        if plugin.linkdirs then
            target:values_add("qt.linkdirs", unpack(table.wrap(plugin.linkdirs)))
        end
    end
end

-- the main entry
function main(target, opt)

    -- init options
    opt = opt or {}

    -- get qt sdk
    local qt = target:data("qt")

    -- get major version
    local major = nil
    if qt.sdkver then
        major = qt.sdkver:split('%.')[1]
    end

    -- add -fPIC
    target:add("cxflags", "-fPIC")
    target:add("mxflags", "-fPIC")
    target:add("asflags", "-fPIC")

    -- need c++11 at least
    local languages = target:get("languages")
    local cxxlang = false
    for _, lang in ipairs(languages) do
        if lang:startswith("cxx") or lang:startswith("c++") then
            cxxlang = true
            break
        end
    end
    if not cxxlang then
        target:add("languages", "cxx11")
    end

    -- add defines for the compile mode
    if is_mode("debug") then
        target:add("defines", "QT_QML_DEBUG")
    elseif is_mode("release") then
        target:add("defines", "QT_NO_DEBUG")
    elseif is_mode("profile") then
        target:add("defines", "QT_QML_DEBUG", "QT_NO_DEBUG")
    end

    -- The following define makes your compiler emit warnings if you use
    -- any feature of Qt which as been marked deprecated (the exact warnings
    -- depend on your compiler). Please consult the documentation of the
    -- deprecated API in order to know how to port your code away from it.
    target:add("defines", "QT_DEPRECATED_WARNINGS")

    -- add plugins
    if opt.plugins then
        _add_plugins(target, opt.plugins)
    end
    local plugins = target:values("qt.plugins")
    if plugins then
        local importfile = path.join(config.buildir(), ".qt", "plugin", target:name(), "static_import.cpp")
        local file = io.open(importfile, "w")
        if file then
            file:print("#include <QtPlugin>")
            for _, plugin in ipairs(plugins) do
                file:print("Q_IMPORT_PLUGIN(%s)", plugin)
            end
            file:close()
            target:add("files", importfile)
        end
    end

    -- add qt links and directories
    for _, qt_linkdir in ipairs(target:values("qt.linkdirs")) do
        local linkdir = path.join(qt.sdkdir, qt_linkdir)
        if os.isdir(linkdir) then
            target:add("linkdirs", linkdir)
        end
    end
    target:add("links", target:values("qt.links"))

    -- add frameworks
    if opt.frameworks then
        target:add("frameworks", opt.frameworks)
    end

    -- do frameworks for qt
    local useframeworks = false
    for _, framework in ipairs(target:get("frameworks")) do

        -- translate qt frameworks
        if framework:startswith("Qt") then

            -- add defines
            target:add("defines", "QT_" .. framework:sub(3):upper() .. "_LIB")
            
            -- add includedirs 
            if is_plat("macosx") then
                local frameworkdir = path.join(qt.sdkdir, "lib", framework .. ".framework")
                if os.isdir(frameworkdir) then
                    target:add("includedirs", path.join(frameworkdir, "Headers"))
                    useframeworks = true
                else
                    target:add("links", _link(framework, major))
                    target:add("includedirs", path.join(qt.sdkdir, "include", framework))
                end
            else 
                target:add("links", _link(framework, major))
                target:add("includedirs", path.join(qt.sdkdir, "include", framework))
            end
        end
    end

    -- add includedirs, linkdirs 
    if is_plat("macosx") then
        target:add("frameworks", "DiskArbitration", "IOKit", "CoreFoundation", "CoreGraphics", "OpenGL")
        target:add("frameworks", "Carbon", "Foundation", "AppKit", "Security", "SystemConfiguration")
        if useframeworks then
            target:add("frameworkdirs", qt.linkdirs)
            target:add("rpathdirs", "@executable_path/Frameworks", qt.linkdirs)
        else
            target:add("rpathdirs", qt.linkdirs)
            target:add("includedirs", path.join(qt.sdkdir, "include"))

            -- remove qt frameworks
            local frameworks = table.wrap(target:get("frameworks"))
            for i = #frameworks, 1, -1 do
                local framework = frameworks[i]
                if framework:startswith("Qt") then
                    table.remove(frameworks, i)
                end
            end
            target:set("frameworks", frameworks)
        end
        target:add("includedirs", path.join(qt.sdkdir, "mkspecs/macx-clang"))
        target:add("linkdirs", qt.linkdirs)

    elseif is_plat("linux") then
        target:set("frameworks", nil)
        target:add("includedirs", path.join(qt.sdkdir, "include"))
        target:add("includedirs", path.join(qt.sdkdir, "mkspecs/linux-g++"))
        target:add("rpathdirs", qt.linkdirs)
        target:add("linkdirs", qt.linkdirs)
    elseif is_plat("windows") then
        target:set("frameworks", nil)
        target:add("includedirs", path.join(qt.sdkdir, "include"))
        target:add("includedirs", path.join(qt.sdkdir, "mkspecs/win32-msvc"))
        target:add("linkdirs", qt.linkdirs)
        target:add("syslinks", "ws2_32", "gdi32", "ole32", "advapi32", "shell32", "user32", "OpenGL32", "imm32", "winmm", "iphlpapi")
    elseif is_plat("mingw") then
        target:set("frameworks", nil)
        target:add("includedirs", path.join(qt.sdkdir, "include"))
        target:add("includedirs", path.join(qt.sdkdir, "mkspecs/win32-g++"))
        target:add("linkdirs", qt.linkdirs)
        target:add("links", "mingw32")
    elseif is_plat("android") then
        target:set("frameworks", nil)
        target:add("includedirs", path.join(qt.sdkdir, "include"))
        target:add("includedirs", path.join(qt.sdkdir, "mkspecs/android-clang"))
        target:add("rpathdirs", qt.linkdirs)
        target:add("linkdirs", qt.linkdirs)
    end

    -- add some static third-party links if exists
    target:add("links", _find_static_links(qt.linkdirs, is_plat("windows") and "qt*.lib" or "libqt*.a"))

    -- is gui application?
    if opt.gui then
        -- add -subsystem:windows for windows platform
        if is_plat("windows") then
            target:add("defines", "_WINDOWS")
            target:add("ldflags", "-subsystem:windows", "-entry:mainCRTStartup", {force = true})
        elseif is_plat("mingw") then
            target:add("ldflags", "-mwindows", {force = true})
        end
    end

end

