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
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.base.semver")
import("core.project.config")
import("core.project.target", {alias = "core_target"})
import("core.base.hashset")
import("lib.detect.find_library")

-- make link for framework
function _link(target, linkdirs, framework, qt_sdkver)
    if framework:startswith("Qt") then
        local debug_suffix = "_debug"
        if target:is_plat("windows") then
            debug_suffix = "d"
        elseif target:is_plat("mingw") then
            debug_suffix = "d"
        elseif target:is_plat("android") or target:is_plat("linux") then
            debug_suffix = ""
        end
        if qt_sdkver:ge("5.0") then
            framework = "Qt" .. qt_sdkver:major() .. framework:sub(3) .. (is_mode("debug") and debug_suffix or "")
        else -- for qt4.x, e.g. QtGui4.lib
            if target:is_plat("windows", "mingw") then
                framework = "Qt" .. framework:sub(3) .. (is_mode("debug") and debug_suffix or "") .. qt_sdkver:major()
            else 
                framework = "Qt" .. framework:sub(3) .. (is_mode("debug") and debug_suffix or "") 
            end
        end
        if target:is_plat("android") then --> -lQt5Core_armeabi/-lQt5CoreDebug_armeabi for 5.14.x
            local libinfo = find_library(framework .. "_" .. config.arch(), linkdirs)
            if libinfo and libinfo.link then
                framework = libinfo.link
            end
        end
    end
    return framework
end

-- find the static links from the given qt link directories, e.g. libqt*.a
function _find_static_links_3rd(target, linkdirs, qt_sdkver, libpattern)
    local links = {}
    local debug_suffix = "_debug"
    if target:is_plat("windows") then
        debug_suffix = "d"
    elseif target:is_plat("mingw") then
        debug_suffix = "d"
    elseif target:is_plat("android") or target:is_plat("linux") then
        debug_suffix = ""
    end
    for _, linkdir in ipairs(linkdirs) do
        for _, libpath in ipairs(os.files(path.join(linkdir, libpattern))) do
            local basename = path.basename(libpath)
            -- we need ignore qt framework libraries, e.g. libQt5xxx.a, Qt5Core.lib ..
            if not basename:startswith("libQt" .. qt_sdkver:major()) and not basename:startswith("Qt" .. qt_sdkver:major()) then
                if (is_mode("debug") and basename:endswith(debug_suffix)) or (not is_mode("debug") and not basename:endswith(debug_suffix)) then
                    table.insert(links, core_target.linkname(path.filename(libpath)))
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
            target:values_add("qt.links", table.unpack(table.wrap(plugin.links)))
        end
        if plugin.linkdirs then
            target:values_add("qt.linkdirs", table.unpack(table.wrap(plugin.linkdirs)))
        end
    end
end

-- add includedirs if exists
function _add_includedirs(target, includedirs)
    for _, includedir in ipairs(includedirs) do
        if os.isdir(includedir) then
            target:add("sysincludedirs", includedir)
        end
    end
end

-- get target c++ version
function _get_target_cppversion(target)
    local languages = target:get("languages")
    for _, language in ipairs(languages) do
        if language:startswith("c++") or language:startswith("cxx") then
            local v = language:match("%d+") or language:match("latest")
            if v then return v end
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
    if not target:is_plat("windows", "mingw") then
        target:add("cxflags", "-fPIC")
        target:add("mxflags", "-fPIC")
        target:add("asflags", "-fPIC")
    end

    -- need c++11 at least
    local languages = target:get("languages")
    local cxxlang = false
    for _, lang in ipairs(languages) do
        if lang:startswith("xx") or lang:startswith("++") then
            cxxlang = true
            break
        end
    end
    if not cxxlang then
        -- Qt6 require at least '/std:c++17'
        -- @see https://github.com/xmake-io/xmake/issues/1183
        local cppversion = _get_target_cppversion(target)
        if qt_sdkver:ge("6.0") then
            -- add conditionnaly c++17 to avoid for example "cl : Command line warning D9025 : overriding '/std:c++latest' with '/std:c++17'" warning
            if (not cppversion) or (cppversion ~= "latest") or (tonumber(cppversion) and tonumber(cppversion) < 17) then
                target:add("languages", "c++17")
            end
            -- @see https://github.com/xmake-io/xmake/issues/2071
            if target:is_plat("windows") then
                target:add("cxxflags", "/Zc:__cplusplus")
                target:add("cxxflags", "/permissive-")
            end
        else
            -- add conditionnaly c++11 to avoid for example "cl : Command line warning D9025 : overriding '/std:c++latest' with '/std:c++11'" warning
            if (not cppversion) or (cppversion ~= "latest") or (tonumber(cppversion) and tonumber(cppversion) < 11) then
                target:add("languages", "c++11")
            end
        end
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
    local frameworksset = hashset.new()
    for _, framework in ipairs(target:get("frameworks")) do

        -- translate qt frameworks
        if framework:startswith("Qt") then
            -- add private includedirs
            if framework:lower():endswith("private") then
                local private_dir = framework:sub(1, -#("private") - 1);
                if target:is_plat("macosx") then
                    local frameworkdir = path.join(qt.libdir, framework .. ".framework")
                    if os.isdir(frameworkdir) then
                        _add_includedirs(target, path.join(frameworkdir, "Headers", qt.sdkver))
                        _add_includedirs(target, path.join(frameworkdir, "Headers", qt.sdkver, private_dir))
                    else
                        _add_includedirs(target, path.join(qt.includedir, private_dir, qt.sdkver, private_dir))
                        _add_includedirs(target, path.join(qt.includedir, private_dir, qt.sdkver))
                    end
                else
                    _add_includedirs(target, path.join(qt.includedir, private_dir, qt.sdkver, private_dir))
                    _add_includedirs(target, path.join(qt.includedir, private_dir, qt.sdkver))
                end
            else
                -- add defines
                target:add("defines", "QT_" .. framework:sub(3):upper() .. "_LIB")

                -- add includedirs
                if target:is_plat("macosx") then
                    local frameworkdir = path.join(qt.libdir, framework .. ".framework")
                    if os.isdir(frameworkdir) and os.isdir(path.join(frameworkdir, "Headers")) then
                        _add_includedirs(target, path.join(frameworkdir, "Headers"))
                        -- e.g. QtGui.framework/Headers/5.15.0/QtGui/qpa/qplatformopenglcontext.h
                        -- https://github.com/xmake-io/xmake/issues/1226
                        _add_includedirs(target, path.join(frameworkdir, "Headers", qt.sdkver))
                        _add_includedirs(target, path.join(frameworkdir, "Headers", qt.sdkver, framework))
                        frameworksset:insert(framework)
                    else
                        target:add("syslinks", _link(target, qt.libdir, framework, qt_sdkver))
                        _add_includedirs(target, path.join(qt.includedir, framework))
                        -- e.g. QtGui/5.15.0/QtGui/qpa/qplatformopenglcontext.h
                        _add_includedirs(target, path.join(qt.includedir, framework, qt.sdkver))
                        _add_includedirs(target, path.join(qt.includedir, framework, qt.sdkver, framework))
                    end
                else
                    target:add("syslinks", _link(target, qt.libdir, framework, qt_sdkver))
                    _add_includedirs(target, path.join(qt.includedir, framework))
                    _add_includedirs(target, path.join(qt.includedir, framework, qt.sdkver))
                    _add_includedirs(target, path.join(qt.includedir, framework, qt.sdkver, framework))
                end
            end
        end
    end

    -- remove private frameworks
    local local_frameworks = {}
    for _, framework in ipairs(target:get("frameworks")) do
        if frameworksset:has(framework) then
            table.insert(local_frameworks, framework)
        end
    end
    target:set("frameworks", local_frameworks)

    -- add some static third-party links if exists, e.g. libqtmain.a, libqtfreetype.q, libqtlibpng.a
    -- and exclude qt framework libraries, e.g. libQt5xxx.a, Qt5xxx.lib
    target:add("syslinks", _find_static_links_3rd(target, qt.libdir, qt_sdkver, target:is_plat("windows") and "qt*.lib" or "libqt*.a"))

    -- add user syslinks
    if syslinks_user then
        target:add("syslinks", syslinks_user)
    end

    -- add includedirs, linkdirs
    if target:is_plat("macosx") then
        target:add("frameworks", "DiskArbitration", "IOKit", "CoreFoundation", "CoreGraphics", "OpenGL")
        target:add("frameworks", "Carbon", "Foundation", "AppKit", "Security", "SystemConfiguration")
        if not frameworksset:empty() then
            target:add("frameworkdirs", qt.libdir)
            target:add("rpathdirs", "@executable_path/Frameworks", qt.libdir)
        else
            target:add("rpathdirs", qt.libdir)
            _add_includedirs(target, qt.includedir)

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
        _add_includedirs(target, path.join(qt.mkspecsdir, "macx-clang"))
        target:add("linkdirs", qt.libdir)
    elseif target:is_plat("linux") then
        target:set("frameworks", nil)
        _add_includedirs(target, qt.includedir)
        _add_includedirs(target, path.join(qt.mkspecsdir, "linux-g++"))
        target:add("rpathdirs", qt.libdir)
        target:add("linkdirs", qt.libdir)
    elseif target:is_plat("windows") then
        target:set("frameworks", nil)
        _add_includedirs(target, qt.includedir)
        _add_includedirs(target, path.join(qt.mkspecsdir, "win32-msvc"))
        target:add("linkdirs", qt.libdir)
        target:add("syslinks", "ws2_32", "gdi32", "ole32", "advapi32", "shell32", "user32", "opengl32", "imm32", "winmm", "iphlpapi")
    elseif target:is_plat("mingw") then
        target:set("frameworks", nil)
        -- we need fix it, because gcc maybe does not work on latest mingw when `-isystem D:\a\_temp\msys64\mingw64\include` is passed.
        -- and qt.includedir will be this path value when Qt sdk directory just is `D:\a\_temp\msys64\mingw64`
        -- @see https://github.com/msys2/MINGW-packages/issues/10761#issuecomment-1044302523
        if qt.includedir and os.isdir(qt.includedir) then
            _add_includedirs(target, qt.includedir)
        end
        _add_includedirs(target, path.join(qt.mkspecsdir, "win32-g++"))
        target:add("linkdirs", qt.libdir)
        target:add("syslinks", "mingw32", "ws2_32", "gdi32", "ole32", "advapi32", "shell32", "user32", "iphlpapi")
    elseif target:is_plat("android") then
        target:set("frameworks", nil)
        _add_includedirs(target, qt.includedir)
        _add_includedirs(target, path.join(qt.mkspecsdir, "android-clang"))
        target:add("rpathdirs", qt.libdir)
        target:add("linkdirs", qt.libdir)
    elseif target:is_plat("wasm") then
        target:set("frameworks", nil)
        _add_includedirs(target, qt.includedir)
        _add_includedirs(target, path.join(qt.mkspecsdir, "wasm-emscripten"))
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
        if target:is_plat("windows") then
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
        elseif target:is_plat("mingw") then
            target:add("ldflags", "-mwindows", {force = true})
        end
    end
end

