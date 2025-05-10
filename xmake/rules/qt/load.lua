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
function _link(target, linkdirs, framework, qt_sdkver, infix)
    if framework:startswith("Qt") then
        local debug_suffix = "_debug"
        if target:is_plat("windows") then
            debug_suffix = "d"
        elseif target:is_plat("mingw") then
            if qt_sdkver:ge("5.15.2") then
                debug_suffix = ""
            else
                debug_suffix = "d"
            end
        elseif target:is_plat("android") or target:is_plat("linux") then
            debug_suffix = ""
        end
        if qt_sdkver:ge("5.0") then
            framework = "Qt" .. qt_sdkver:major() .. framework:sub(3) .. infix .. (is_mode("debug") and debug_suffix or "")
        else -- for qt4.x, e.g. QtGui4.lib
            if target:is_plat("windows", "mingw") then
                framework = "Qt" .. framework:sub(3) .. infix .. (is_mode("debug") and debug_suffix or "") .. qt_sdkver:major()
            else
                framework = "Qt" .. framework:sub(3) .. infix .. (is_mode("debug") and debug_suffix or "")
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
            -- we need to ignore qt framework libraries, e.g. libQt5xxx.a, Qt5Core.lib ..
            -- but bundled library names like libQt5Bundledxxx.a on Qt6.x
            -- @see https://github.com/xmake-io/xmake/issues/3572
            if basename:startswith("libQt" .. qt_sdkver:major() .. "Bundled") or (
                (not basename:startswith("libQt" .. qt_sdkver:major())) and
                (not basename:startswith("Qt" .. qt_sdkver:major()))) then
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
        -- TODO: add prebuilt object files in qt sdk.
        -- these file is located at plugins/xxx/objects-Release/xxxPlugin_init/xxxPlugin_init.cpp.o
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

-- get frameworks from target
-- @see https://github.com/xmake-io/xmake/issues/4135
function _get_frameworks_from_target(target)
    local values = table.wrap(target:get("frameworks"))
    for _, value in ipairs((target:get_from("frameworks", "option::*"))) do
        table.join2(values, value)
    end
    for _, value in ipairs((target:get_from("frameworks", "package::*"))) do
        table.join2(values, value)
    end
    for _, value in ipairs((target:get_from("__qt_frameworks", "dep::*", {interface = true}))) do
        table.join2(values, value)
    end
    return table.unique(values)
end

function _add_qmakeprllibs(target, prlfile, qt)
    if os.isfile(prlfile) then
        local contents = io.readfile(prlfile)
        local envs = {}
        if contents then
            for _, prlenv in ipairs(contents:split('\n', {plain = true})) do
                local kv = prlenv:split('=', {plain = true})
                if #kv == 2 then
                    envs[kv[1]:trim()] = kv[2]:trim()
                end
            end
        end
        if envs.QMAKE_PRL_LIBS_FOR_CMAKE then
            for _, lib in ipairs(envs.QMAKE_PRL_LIBS_FOR_CMAKE:split(';', {plain = true})) do
                if lib:startswith("-L") then
                    local libdir = lib:sub(3)
                    target:add("linkdirs", libdir)
                else
                    if qt.qmldir then
                        lib = string.gsub(lib, "%$%$%[QT_INSTALL_QML%]", qt.qmldir)
                    end
                    if qt.sdkdir then
                        lib = string.gsub(lib, "%$%$%[QT_INSTALL_PREFIX%]", qt.sdkdir)
                    end
                    if qt.pluginsdir then
                        lib = string.gsub(lib, "%$%$%[QT_INSTALL_PLUGINS%]", qt.pluginsdir)
                    end
                    if qt.libdir then
                        lib = string.gsub(lib, "%$%$%[QT_INSTALL_LIBS%]", qt.libdir)
                    end
                    if lib:startswith("-l") then
                        lib = lib:sub(3)
                    end
                    target:add("syslinks", lib)
                end
            end
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

    -- get qt sdk infix
    local infix = ""
    if qt.mkspecsdir then
        if os.isfile(path.join(qt.mkspecsdir, "qconfig.pri")) then
            local qconfig = io.readfile(path.join(qt.mkspecsdir, "qconfig.pri"))
            if qconfig then
                qconfig = qconfig:trim():split("\n")
                for _, line in ipairs(qconfig) do
                    if line:startswith("QT_LIBINFIX") then
                        local kv = line:split("=", {plain = true, limit = 2})
                        if #kv == 2 then
                            infix = kv[2]:trim()
                        end
                    end
                end
            end
        end
    end

    -- add -fPIC
    if not target:is_plat("windows", "mingw") then
        target:add("cxflags", "-fPIC")
        target:add("mxflags", "-fPIC")
        target:add("asflags", "-fPIC")
    end

    if qt_sdkver:ge("6.0") then
        -- @see https://github.com/xmake-io/xmake/issues/2071
        if target:is_plat("windows") then
            target:add("cxxflags", "/Zc:__cplusplus")
            target:add("cxxflags", "/permissive-")
        end
    end
    -- need c++11 at least
    local languages = target:get("languages")
    local cxxlang = false
    for _, lang in ipairs(languages) do
        -- c++* or gnuc++*
        if lang:find("cxx", 1, true) or lang:find("c++", 1, true) then
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
            if (not cppversion) or (tonumber(cppversion) and tonumber(cppversion) < 17) then
                target:add("languages", "c++17")
            end
        else
            -- add conditionnaly c++11 to avoid for example "cl : Command line warning D9025 : overriding '/std:c++latest' with '/std:c++11'" warning
            if (not cppversion) or (tonumber(cppversion) and tonumber(cppversion) < 11) then
                target:add("languages", "c++11")
            end
        end
    end

    -- add definitions for the compile mode
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
        local importfile = path.join(config.builddir(), ".qt", "plugin", target:name(), "static_import.cpp")
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

    -- backup the user syslinks, we need to add them behind the qt syslinks
    local syslinks_user = target:get("syslinks")
    target:set("syslinks", nil)

    -- add qt links and directories
    target:add("syslinks", target:values("qt.links"))
    local qtprldirs = {}
    for _, qt_linkdir in ipairs(target:values("qt.linkdirs")) do
        local linkdir = path.join(qt.sdkdir, qt_linkdir)
        if os.isdir(linkdir) then
            target:add("linkdirs", linkdir)
            table.insert(qtprldirs, linkdir)
        end
    end
    for _, qt_link in ipairs(target:values("qt.links")) do
        for _, qt_libdir in ipairs(qtprldirs) do
            local prl_file = path.join(qt_libdir, qt_link .. ".prl")
            _add_qmakeprllibs(target, prl_file, qt)
        end
    end

    -- backup qt frameworks
    local qt_frameworks = target:get("frameworks")
    if qt_frameworks then
        target:set("__qt_frameworks", qt_frameworks)
    end
    local qt_frameworks_extra = target:extraconf("frameworks")
    if qt_frameworks_extra then
        target:extraconf_set("__qt_frameworks", qt_frameworks_extra)
    end

    -- add frameworks
    if opt.frameworks then
        target:add("frameworks", opt.frameworks)
    end

    -- do frameworks for qt
    local frameworksset = hashset.new()
    local qt_frameworks = _get_frameworks_from_target(target)
    for _, framework in ipairs(qt_frameworks) do

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
                -- add definitions
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
                        local link = _link(target, qt.libdir, framework, qt_sdkver, infix)
                        target:add("syslinks", link)
                        _add_qmakeprllibs(target, path.join(qt.libdir, link .. ".prl"), qt)
                        _add_includedirs(target, path.join(qt.includedir, framework))
                        -- e.g. QtGui/5.15.0/QtGui/qpa/qplatformopenglcontext.h
                        _add_includedirs(target, path.join(qt.includedir, framework, qt.sdkver))
                        _add_includedirs(target, path.join(qt.includedir, framework, qt.sdkver, framework))
                    end
                else
                    local link = _link(target, qt.libdir, framework, qt_sdkver, infix)
                    target:add("syslinks", link)
                    _add_qmakeprllibs(target, path.join(qt.libdir, link .. ".prl"), qt)
                    _add_includedirs(target, path.join(qt.includedir, framework))
                    _add_includedirs(target, path.join(qt.includedir, framework, qt.sdkver))
                    _add_includedirs(target, path.join(qt.includedir, framework, qt.sdkver, framework))
                end
            end
        elseif target:is_plat("macosx") then
            --@see https://github.com/xmake-io/xmake/issues/5336
            frameworksset:insert(framework)
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

    -- add some static third-party links if exists
    -- and exclude qt framework libraries, e.g. libQt5xxx.a, Qt5xxx.lib
    local libpattern
    if qt_sdkver:ge("6.0") then
        -- e.g. libQt6BundledFreetype.a on Qt6.x
        -- @see https://github.com/xmake-io/xmake/issues/3572
        libpattern = target:is_plat("windows") and "Qt*.lib" or "libQt*.a"
    else
        -- e.g. libqtmain.a, libqtfreetype.q, libqtlibpng.a on Qt5.x
        libpattern = target:is_plat("windows") and "qt*.lib" or "libqt*.a"
    end
    target:add("syslinks", _find_static_links_3rd(target, qt.libdir, qt_sdkver, libpattern))

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
        _add_includedirs(target, qt.includedir)
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
        -- for debugger, https://github.com/xmake-io/xmake-vscode/issues/225
        if qt.bindir_host then
            target:add("runenvs", "PATH", qt.bindir_host)
        end
        if qt.bindir then
            target:add("runenvs", "PATH", qt.bindir)
        end
    elseif target:is_plat("mingw") then
        target:set("frameworks", nil)
        -- we need to fix it, because gcc maybe does not work on latest mingw when `-isystem D:\a\_temp\msys64\mingw64\include` is passed.
        -- and qt.includedir will be this path value when Qt sdk directory just is `D:\a\_temp\msys64\mingw64`
        -- @see https://github.com/msys2/MINGW-packages/issues/10761#issuecomment-1044302523
        if is_subhost("msys") then
            local mingw_prefix = os.getenv("MINGW_PREFIX")
            local mingw_includedir = path.normalize(path.join(mingw_prefix or "/", "include"))
            if qt.includedir and qt.includedir and path.normalize(qt.includedir) ~= mingw_includedir then
                _add_includedirs(target, qt.includedir)
            end
        else
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
        -- add prebuilt object files in qt sdk.
        -- these files are located at lib/objects-Release/xxxmodule_resources_x/.rcc/xxxmodule.cpp.o
        for _, framework in ipairs(qt_frameworks) do
            local prefix = framework
            if framework:startswith("Qt") then
                prefix = framework:sub(3)
            end
            for _, filepath in ipairs(os.files(path.join(qt.libdir, "objects-*", prefix .. "_resources_*", ".rcc", "*.o"))) do
                table.insert(target:objectfiles(), filepath)
            end
        end
        target:add("ldflags", "-s FETCH=1", "-s ERROR_ON_UNDEFINED_SYMBOLS=1", "-s ALLOW_MEMORY_GROWTH=1", "--bind")
        target:add("shflags", "-s FETCH=1", "-s ERROR_ON_UNDEFINED_SYMBOLS=1", "-s ALLOW_MEMORY_GROWTH=1", "--bind")
        if qt_sdkver:ge("6.0") then
            -- @see https://github.com/xmake-io/xmake/issues/4137
            target:add("ldflags", "-s MAX_WEBGL_VERSION=2", "-s WASM_BIGINT=1", "-s DISABLE_EXCEPTION_CATCHING=1")
            target:add("ldflags", "-sASYNCIFY_IMPORTS=qt_asyncify_suspend_js,qt_asyncify_resume_js")
            target:add("ldflags", "-s EXPORTED_RUNTIME_METHODS=UTF16ToString,stringToUTF16,JSEvents,specialHTMLTargets")
            target:add("ldflags", "-s MODULARIZE=1", "-s EXPORT_NAME=createQtAppInstance")
            target:add("shflags", "-s MAX_WEBGL_VERSION=2", "-s WASM_BIGINT=1", "-s DISABLE_EXCEPTION_CATCHING=1")
            target:add("shflags", "-sASYNCIFY_IMPORTS=qt_asyncify_suspend_js,qt_asyncify_resume_js")
            target:add("shflags", "-s EXPORTED_RUNTIME_METHODS=UTF16ToString,stringToUTF16,JSEvents,specialHTMLTargets")
            target:add("shflags", "-s MODULARIZE=1", "-s EXPORT_NAME=createQtAppInstance")
            target:set("extension", ".js")
        else
            target:add("ldflags", "-s WASM=1", "-s FULL_ES2=1", "-s FULL_ES3=1", "-s USE_WEBGL2=1")
            target:add("ldflags", "-s EXPORTED_RUNTIME_METHODS=[\"UTF16ToString\",\"stringToUTF16\"]")
            target:add("shflags", "-s WASM=1", "-s FULL_ES2=1", "-s FULL_ES3=1", "-s USE_WEBGL2=1")
            target:add("shflags", "-s EXPORTED_RUNTIME_METHODS=[\"UTF16ToString\",\"stringToUTF16\"]")
        end
    end

    -- is gui application?
    if opt.gui then
        if not target:values("windows.subsystem") then
            target:values_set("windows.subsystem", "windows")
            if target:has_tool("ld", "link", "lld-link") then
                target:add("ldflags", "-entry:mainCRTStartup", {force = true})
            end
        end
    else
        if not target:values("windows.subsystem") then
            target:values_set("windows.subsystem", "console")
        end
    end

    -- set default runtime
    -- @see https://github.com/xmake-io/xmake/issues/4161
    if not target:get("runtimes") then
        target:set("runtimes", is_mode("debug") and "MDd" or "MD")
    end
end

