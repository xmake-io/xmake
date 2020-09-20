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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.base.semver")
import("core.project.config")
import("core.project.target")
import("lib.detect.find_library")

-- make link for framework
function _link(linkdirs, framework, qt_sdkver)
    if framework:startswith("Qt") then
        local debug_suffix = "_debug"
        if is_plat("windows") then
            debug_suffix = "d"
        elseif is_plat("mingw") then
            debug_suffix = "d"
        elseif is_plat("android") or is_plat("linux") then
            debug_suffix = ""
        end
        framework = "Qt" .. qt_sdkver:major() .. framework:sub(3) .. (is_mode("debug") and debug_suffix or "")
        if is_plat("android") then --> -lQt5Core_armeabi/-lQt5CoreDebug_armeabi for 5.14.x
            local libinfo = find_library(framework .. "_" .. config.arch(), linkdirs)
            if libinfo and libinfo.link then
                framework = libinfo.link
            end
        end
    end
    return framework
end

-- find the static links from the given qt link directories, e.g. libqt*.a
function _find_static_links_3rd(linkdirs, qt_sdkver, libpattern)
    local links = {}
    local debug_suffix = "_debug"
    if is_plat("windows") then
        debug_suffix = "d"
    elseif is_plat("mingw") then
        debug_suffix = "d"
    elseif is_plat("android") or is_plat("linux") then
        debug_suffix = ""
    end
    for _, linkdir in ipairs(linkdirs) do
        for _, libpath in ipairs(os.files(path.join(linkdir, libpattern))) do
            local basename = path.basename(libpath)
            -- we need ignore qt framework libraries, e.g. libQt5xxx.a, Qt5Core.lib ..
            if not basename:startswith("libQt" .. qt_sdkver:major()) and not basename:startswith("Qt" .. qt_sdkver:major()) then
                if (is_mode("debug") and basename:endswith(debug_suffix)) or (not is_mode("debug") and not basename:endswith(debug_suffix)) then
                    table.insert(links, target.linkname(path.filename(libpath)))
                end
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

    -- get qt sdk version
    local qt_sdkver = nil
    if qt.sdkver then
        qt_sdkver = semver.new(qt.sdkver)
    else
        raise("Qt SDK version not found, please run `xmake f --qt_sdkver=xxx` to set it.")
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

    -- backup the user syslinks, we need add them behind the qt syslinks
    local syslinks_user = target:get("syslinks")
    target:set("syslinks", nil)

    -- add qt links and directories
    for _, qt_linkdir in ipairs(target:values("qt.linkdirs")) do
        local linkdir = path.join(qt.sdkdir, qt_linkdir)
        if os.isdir(linkdir) then
            target:add("linkdirs", linkdir)
        end
    end
    target:add("syslinks", target:values("qt.links"))

    -- add frameworks
    if opt.frameworks then
        target:add("frameworks", opt.frameworks)
    end

    -- do frameworks for qt
    local useframeworks = false
    for _, framework in ipairs(target:get("frameworks")) do

        -- translate qt frameworks
        if framework:startswith("Qt") then
            -- add private includedirs
            if framework:lower():endswith("private") then
                local private_dir = framework:sub(1, -#("private") - 1);
                if is_plat("macosx") then
                    local frameworkdir = path.join(qt.libdir, framework .. ".framework")
                    if os.isdir(frameworkdir) then
                        target:add("includedirs", path.join(frameworkdir, "Headers", qt.sdkver))
                        target:add("includedirs", path.join(frameworkdir, "Headers", qt.sdkver, private_dir))
                    else
                        target:add("includedirs", path.join(qt.includedir, private_dir, qt.sdkver, private_dir))
                        target:add("includedirs", path.join(qt.includedir, private_dir, qt.sdkver))
                    end
                else
                    target:add("includedirs", path.join(qt.includedir, private_dir, qt.sdkver, private_dir))
                    target:add("includedirs", path.join(qt.includedir, private_dir, qt.sdkver))
                end
            else
                -- add defines
                target:add("defines", "QT_" .. framework:sub(3):upper() .. "_LIB")

                -- add includedirs
                if is_plat("macosx") then
                    local frameworkdir = path.join(qt.libdir, framework .. ".framework")
                    if os.isdir(frameworkdir) then
                        target:add("includedirs", path.join(frameworkdir, "Headers"))
                        useframeworks = true
                    else
                        target:add("syslinks", _link(qt.libdir, framework, qt_sdkver))
                        target:add("includedirs", path.join(qt.includedir, framework))
                    end
                else
                    target:add("syslinks", _link(qt.libdir, framework, qt_sdkver))
                    target:add("includedirs", path.join(qt.includedir, framework))
                end
            end
        end
    end

    -- remove private frameworks
    local local_frameworks = {}
    for _, framework in ipairs(target:get("frameworks")) do
        if not framework:lower():endswith("private") then
            table.insert(local_frameworks, framework)
        end
    end
    target:set("frameworks", local_frameworks)

    -- add some static third-party links if exists, e.g. libqtmain.a, libqtfreetype.q, libqtlibpng.a
    -- and exclude qt framework libraries, e.g. libQt5xxx.a, Qt5xxx.lib
    target:add("syslinks", _find_static_links_3rd(qt.libdir, qt_sdkver, is_plat("windows") and "qt*.lib" or "libqt*.a"))

    -- add user syslinks
    if syslinks_user then
        target:add("syslinks", syslinks_user)
    end

    -- add includedirs, linkdirs
    if is_plat("macosx") then
        target:add("frameworks", "DiskArbitration", "IOKit", "CoreFoundation", "CoreGraphics", "OpenGL")
        target:add("frameworks", "Carbon", "Foundation", "AppKit", "Security", "SystemConfiguration")
        if useframeworks then
            target:add("frameworkdirs", qt.libdir)
            target:add("rpathdirs", "@executable_path/Frameworks", qt.libdir)
        else
            target:add("rpathdirs", qt.libdir)
            target:add("includedirs", qt.includedir)

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
        target:add("includedirs", path.join(qt.mkspecsdir, "macx-clang"))
        target:add("linkdirs", qt.libdir)
    elseif is_plat("linux") then
        target:set("frameworks", nil)
        target:add("includedirs", qt.includedir)
        target:add("includedirs", path.join(qt.mkspecsdir, "linux-g++"))
        target:add("rpathdirs", qt.libdir)
        target:add("linkdirs", qt.libdir)
    elseif is_plat("windows") then
        target:set("frameworks", nil)
        target:add("includedirs", qt.includedir)
        target:add("includedirs", path.join(qt.mkspecsdir, "win32-msvc"))
        target:add("linkdirs", qt.libdir)
        target:add("syslinks", "ws2_32", "gdi32", "ole32", "advapi32", "shell32", "user32", "OpenGL32", "imm32", "winmm", "iphlpapi")
    elseif is_plat("mingw") then
        target:set("frameworks", nil)
        target:add("includedirs", qt.includedir)
        target:add("includedirs", path.join(qt.mkspecsdir, "win32-g++"))
        target:add("linkdirs", qt.libdir)
        target:add("syslinks", "mingw32")
    elseif is_plat("android") then
        target:set("frameworks", nil)
        target:add("includedirs", qt.includedir)
        target:add("includedirs", path.join(qt.mkspecsdir, "android-clang"))
        target:add("rpathdirs", qt.libdir)
        target:add("linkdirs", qt.libdir)
    elseif is_plat("wasm") then
        target:set("frameworks", nil)
        target:add("includedirs", qt.includedir)
        target:add("includedirs", path.join(qt.mkspecsdir, "wasm-emscripten"))
        target:add("rpathdirs", qt.libdir)
        target:add("linkdirs", qt.libdir)
        target:add("ldflags", "-s WASM=1", "-s FETCH=1", "-s FULL_ES2=1", "-s FULL_ES3=1", "-s USE_WEBGL2=1", "--bind")
        target:add("ldflags", "-s ERROR_ON_UNDEFINED_SYMBOLS=1", "-s EXTRA_EXPORTED_RUNTIME_METHODS=[\"UTF16ToString\",\"stringToUTF16\"]", "-s ALLOW_MEMORY_GROWTH=1")
        target:add("shflags", "-s WASM=1", "-s FETCH=1", "-s FULL_ES2=1", "-s FULL_ES3=1", "-s USE_WEBGL2=1", "--bind")
        target:add("shflags", "-s ERROR_ON_UNDEFINED_SYMBOLS=1", "-s EXTRA_EXPORTED_RUNTIME_METHODS=[\"UTF16ToString\",\"stringToUTF16\"]", "-s ALLOW_MEMORY_GROWTH=1")
    end

    -- is gui application?
    if opt.gui then
        -- add -subsystem:windows for windows platform
        if is_plat("windows") then
            target:add("defines", "_WINDOWS")
            local subsystem = false
            for _, ldflag in ipairs(target:get("ldflags")) do
                ldflag = ldflag:lower()
                if ldflag:find("[/%-]subsystem:") then
                    subsystem = true
                    break
                end
            end
            -- maybe user will set subsystem to console
            if not subsystem then
                target:add("ldflags", "-subsystem:windows", "-entry:mainCRTStartup", {force = true})
            end
        elseif is_plat("mingw") then
            target:add("ldflags", "-mwindows", {force = true})
        end
    end
end

