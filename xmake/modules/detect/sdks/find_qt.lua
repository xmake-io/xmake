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
-- @file        find_qt.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.cache.detectcache")

-- find qt sdk directory
function _find_sdkdir(sdkdir, sdkver)

    -- append target sub-directory
    local subdirs = {}
    if is_plat("linux") then
        table.insert(subdirs, path.join(sdkver or "*", is_arch("x86_64") and "gcc_64" or "gcc_32", "bin"))
        table.insert(subdirs, path.join(sdkver or "*", is_arch("x86_64") and "clang_64" or "clang_32", "bin"))
    elseif is_plat("macosx") then
        table.insert(subdirs, path.join(sdkver or "*", "macos", "bin")) -- for Qt 6.2
        table.insert(subdirs, path.join(sdkver or "*", is_arch("x86_64") and "clang_64" or "clang_32", "bin"))
    elseif is_plat("iphoneos") then
        table.insert(subdirs, path.join(sdkver or "*", "ios", "bin"))
    elseif is_plat("windows") then
        local vs = config.get("vs")
        if vs then
            table.insert(subdirs, path.join(sdkver or "*", is_arch("x64") and "msvc" .. vs .. "_64" or "msvc" .. vs .. "_32", "bin"))
            table.insert(subdirs, path.join(sdkver or "*", "msvc" .. vs, "bin"))
        end
        table.insert(subdirs, path.join(sdkver or "*", is_arch("x64") and "msvc*_64" or "msvc*_32", "bin"))
        table.insert(subdirs, path.join(sdkver or "*", "msvc*", "bin"))
    elseif is_plat("mingw") then
        table.insert(subdirs, path.join(sdkver or "*", is_arch("x86_64") and "mingw*_64" or "mingw*_32", "bin"))
    elseif is_plat("android") then
        local subdir
        if is_arch("arm64-v8a") then
            subdir = "android_arm64_v8a"
        elseif is_arch("armeabi-v7a", "armeabi", "armv7-a", "armv5te") then -- armv7-a/armv5te are deprecated
            subdir = "android_armv7"
        elseif is_arch("x86", "i386") then -- i386 is deprecated
            subdir = "android_x86"
        elseif is_arch("x86_64") then
            subdir = "android_x86_64"
        end
        if subdir then
            table.insert(subdirs, path.join(sdkver or "*", subdir, "bin"))
        end
        table.insert(subdirs, path.join(sdkver or "*", "android", "bin"))
    elseif is_plat("wasm") then
        table.insert(subdirs, path.join(sdkver or "*", "wasm_32", "bin"))
    else
        table.insert(subdirs, path.join(sdkver or "*", "*", "bin"))
    end
    table.insert(subdirs, path.join("*", "bin"))
    table.insert(subdirs, "bin")

    -- init the search directories
    local paths = {}
    if sdkdir then
        table.insert(paths, sdkdir)
    end
    if is_host("windows") then

        -- add paths from registry
        local regs =
        {
            "HKEY_CLASSES_ROOT\\Applications\\QtProject.QtCreator.c\\shell\\Open\\Command",
            "HKEY_CLASSES_ROOT\\Applications\\QtProject.QtCreator.cpp\\shell\\Open\\Command",
            "HKEY_CLASSES_ROOT\\Applications\\QtProject.QtCreator.pro\\shell\\Open\\Command",
            "HKEY_CURRENT_USER\\SOFTWARE\\Classes\\Applications\\QtProject.QtCreator.c\\shell\\Open\\Command",
            "HKEY_CURRENT_USER\\SOFTWARE\\Classes\\Applications\\QtProject.QtCreator.cpp\\shell\\Open\\Command",
            "HKEY_CURRENT_USER\\SOFTWARE\\Classes\\Applications\\QtProject.QtCreator.pro\\shell\\Open\\Command"
        }
        for _, reg in ipairs(regs) do
            table.insert(paths, function ()
                local value = val("reg " .. reg)
                if value then
                    local p = value:find("\\Tools\\QtCreator", 1, true)
                    if p then
                        return path.translate(value:sub(1, p - 1))
                    end
                end
            end)
        end

        -- add root logical drive pates, e.g. C:/Qt/Qtx.x.x, D:/Qtx.x.x ..
        for idx, drive in ipairs(winos.logical_drives()) do
            if idx < 5 then
                table.insert(paths, path.join(drive, "Qt", "Qt*"))
            else
                break
            end
        end
    else
        table.insert(paths, "~/Qt")
        table.insert(paths, "~/Qt*")
    end

    -- special case for android on windows, where qmake is a .bat from version 6.3
    if is_host("windows") and is_plat("android") then
        local qmake = find_file("qmake.bat", paths, {suffixes = subdirs})
        if qmake then
            return path.directory(path.directory(qmake)), path.filename(qmake)
        end
    end

    -- attempt to find qmake
    local qmake = find_file(is_host("windows") and "qmake.exe" or "qmake", paths, {suffixes = subdirs})
    if qmake then
        return path.directory(path.directory(qmake)), path.filename(qmake)
    end
end

-- find qmake
function _find_qmake(sdkdir, sdkver)
    local sdkdir, qmakefile = _find_sdkdir(sdkdir, sdkver)
    local qmake = find_tool(qmakefile or "qmake", {paths = sdkdir and path.join(sdkdir, "bin")})
    if qmake then
        return qmake.program
    end
end

-- get qt environment
function _get_qtenvs(qmake)
    local envs = _g._ENVS
    if not envs then
        envs = {}
        local results = try {function () return os.iorunv(qmake, {"-query"}) end}
        if results then
            for _, qtenv in ipairs(results:split('\n', {plain = true})) do
                local kv = qtenv:split(':', {plain = true, limit = 2}) -- @note set limit = 2 for supporting value with win-style path, e.g. `key:C:\xxx`
                if #kv == 2 then
                    envs[kv[1]] = kv[2]:trim()
                end
            end
        end
        _g._ENVS = envs
    end
    return envs
end

-- find qt sdk toolchains
function _find_qt(sdkdir, sdkver)

    -- find qmake
    local qmake = _find_qmake(sdkdir, sdkver)
    if not qmake then
        return
    end

    -- get qt environments
    local qtenvs = _get_qtenvs(qmake)
    if not qtenvs then
        return
    end

    -- get qt toolchains
    sdkdir = qtenvs.QT_INSTALL_PREFIX
    local sdkver = qtenvs.QT_VERSION
    local bindir = qtenvs.QT_INSTALL_BINS
    local libexecdir = qtenvs.QT_INSTALL_LIBEXECS
    local qmldir = qtenvs.QT_INSTALL_QML
    local libdir = qtenvs.QT_INSTALL_LIBS
    local pluginsdir = qtenvs.QT_INSTALL_PLUGINS
    local includedir = qtenvs.QT_INSTALL_HEADERS
    local mkspecsdir = qtenvs.QMAKE_MKSPECS or path.join(qtenvs.QT_INSTALL_ARCHDATA, "mkspecs")
    -- for 6.2
    local bindir_host = qtenvs.QT_HOST_BINS
    if not bindir_host and libexecdir and is_plat("android", "iphoneos") then
        local rootdir = path.directory(path.directory(bindir))
        if is_host("macosx") then
            bindir_host = path.join(rootdir, "macos", "bin")
        else
            -- TODO
        end
    end
    local libexecdir_host = qtenvs.QT_HOST_LIBEXECS
    if not libexecdir_host and libexecdir and is_plat("android", "iphoneos") then
        local rootdir = path.directory(path.directory(libexecdir))
        if is_host("macosx") then
            libexecdir_host = path.join(rootdir, "macos", "libexec")
        else
            -- TODO
        end
    end
    return {sdkdir = sdkdir, bindir = bindir, bindir_host = bindir_host, libexecdir = libexecdir, libexecdir_host = libexecdir_host, libdir = libdir, includedir = includedir, qmldir = qmldir, pluginsdir = pluginsdir, mkspecsdir = mkspecsdir, sdkver = sdkver}
end

-- find qt sdk toolchains
--
-- @param sdkdir    the qt sdk directory
-- @param opt       the argument options, e.g. {verbose = true, force = false, version = "5.9.1"}
--
-- @return          the qt sdk toolchains. e.g. {sdkver = ..., sdkdir = ..., bindir = .., linkdirs = ..., includedirs = ..., .. }
--
-- @code
--
-- local toolchains = find_qt("~/Qt")
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_qt"
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.qt and cacheinfo.qt.sdkdir and os.isdir(cacheinfo.qt.sdkdir) then
        return cacheinfo.qt
    end

    -- find qt
    local qt = _find_qt(sdkdir or config.get("qt") or global.get("qt") or config.get("sdk"), opt.version or config.get("qt_sdkver"))
    if qt then

        -- save to config
        config.set("qt", qt.sdkdir, {force = true, readonly = true})
        config.set("qt_sdkver", qt.sdkver, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for Qt SDK directory ... ${color.success}%s", qt.sdkdir)
            if qt.sdkver then
                cprint("checking for Qt SDK version ... ${color.success}%s", qt.sdkver)
            else
                cprint("checking for Qt SDK version ... ${color.nothing}${text.nothing}")
            end
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for Qt SDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.qt = qt or false
    detectcache:set(key, cacheinfo)
    detectcache:save()
    return qt
end
