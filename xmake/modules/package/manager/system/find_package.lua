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
-- @file        find_package.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_path")
import("lib.detect.find_library")
import("lib.detect.pkgconfig")
import("detect.sdks.find_xcode")
import("core.project.config")

-- find package
function _find_package(name, links, linkdirs, includedirs, opt)

    -- find library
    local result = nil
    for _, link in ipairs(links) do
        local libinfo = find_library(link, linkdirs, {plat = opt.plat})
        if libinfo then
            result          = result or {}
            result.links    = table.join(result.links or {}, libinfo.link)
            result.linkdirs = table.join(result.linkdirs or {}, libinfo.linkdir)
        end
    end

    -- find includes
    if opt.includes then
        for _, include in ipairs(opt.includes) do
            local includedir = find_path(include, includedirs)
            if includedir then
                result             = result or {}
                result.includedirs = table.join(result.includedirs or {}, includedir)
            end
        end
        for _, include in ipairs({name .. "/" .. name .. ".h", name .. ".h"}) do
            local includedir = find_path(include, includedirs)
            if includedir then
                result             = result or {}
                result.includedirs = table.join(result.includedirs or {}, includedir)
                break
            end
        end
    elseif result and result.links and opt.includedirs then
        result.includedirs = opt.includedirs
    end
    return result
end

-- find package from the environment variables
-- @see https://github.com/xmake-io/xmake/issues/1776
--
function _find_package_from_envs(name, links, opt)

    -- add default search includedirs on pc host
    local includedirs = table.wrap(opt.includedirs)
    if #includedirs == 0 then
        if opt.plat == "windows" then
            table.insert(includedirs, "$(env INCLUDE)")
        else
            table.insert(includedirs, "$(env CPATH)")
            table.insert(includedirs, "$(env C_INCLUDE_PATH)")
            table.insert(includedirs, "$(env CPLUS_INCLUDE_PATH)")
        end
    end

    -- add default search linkdirs on pc host
    local linkdirs = table.wrap(opt.linkdirs)
    if #linkdirs == 0 then
        if opt.plat == "windows" then
            table.insert(linkdirs, "$(env LIB)")
        else
            table.insert(linkdirs, "$(env LIBRARY_PATH)")
        end
    end
    return _find_package(name, links, linkdirs, includedirs, opt)
end

-- find package from the unix-like system directories
function _find_package_from_unixdirs(name, links, opt)

    -- add default search includedirs on pc host
    local includedirs = table.wrap(opt.includedirs)
    if #includedirs == 0 then
        if opt.plat == "linux" or opt.plat == "macosx" then
            table.insert(includedirs, "/usr/local/include")
            table.insert(includedirs, "/usr/include")
            table.insert(includedirs, "/opt/local/include")
            table.insert(includedirs, "/opt/include")
        end
    end

    -- add default search linkdirs on pc host
    local linkdirs = table.wrap(opt.linkdirs)
    if #linkdirs == 0 then
        if opt.plat == "linux" or opt.plat == "macosx" then
            table.insert(linkdirs, "/usr/local/lib")
            table.insert(linkdirs, "/usr/lib")
            table.insert(linkdirs, "/opt/local/lib")
            table.insert(linkdirs, "/opt/lib")
            if opt.plat == "linux" and opt.arch == "x86_64" then
                table.insert(linkdirs, "/usr/local/lib/x86_64-linux-gnu")
                table.insert(linkdirs, "/usr/lib/x86_64-linux-gnu")
                table.insert(linkdirs, "/usr/lib64")
                table.insert(linkdirs, "/opt/lib64")
            end
        end
    end
    return _find_package(name, links, linkdirs, includedirs, opt)
end

-- find package from the xcode directories
function _find_package_from_xcodedirs(name, links, opt)

    -- find xcode first
    local xcode = find_xcode(config.get("xcode"), {plat = opt.plat, arch = opt.arch})
    if not xcode then
        return
    end

    -- get sdk root directory
    local platname = nil
    if opt.plat == "macosx" then
        platname = "MacOSX"
    elseif opt.plat == "iphoneos" then
        platname = (opt.arch == "i386" or opt.arch == "x86_64") and "iPhoneSimulator" or "iPhoneOS"
    elseif opt.plat == "watchos" then
        platname = opt.arch == "i386" and "WatchSimulator" or "WatchOS"
    end
    local sdk_rootdir = format("%s/Contents/Developer/Platforms/%s.platform/Developer/SDKs/%s%s.sdk", xcode.sdkdir, platname, platname, xcode.sdkver)

    -- init include and link directories
    local linkdirs    = {path.join(sdk_rootdir, "usr", "lib")}
    local includedirs = {path.join(sdk_rootdir, "usr", "include")}

    -- find library
    local result = nil
    for _, link in ipairs(links) do
        if find_file("lib" .. link .. ".tbd", linkdirs) then
            result          = result or {}
            result.links    = table.join(result.links or {}, link)
        end
    end
    if result then
        -- we need not add linkdirs again if we are building target on the current platform (with -isysroot)
        if config.plat() ~= opt.plat or config.arch() ~= opt.arch then
            result.linkdirs    = linkdirs
            result.includedirs = includedirs
        end
    end
    return result
end

-- find package from the system directories
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- init options
    opt = opt or {}

    -- attempt to get links from pkg-config
    local pkginfo = nil
    local version = nil
    local links = table.wrap(opt.links)
    if #links == 0 then
        pkginfo = pkgconfig.libinfo(name)
        if pkginfo then
            links = table.wrap(pkginfo.links)
            version = pkginfo.version
        end
    end

    -- uses name as links directly e.g. libname.a
    if #links == 0 then
        links = table.wrap(name)
    end

    -- init finders
    local finders = {}
    if opt.plat == os.host() and opt.arch == os.arch() then
        if opt.plat ~= "windows" then
            table.insert(finders, _find_package_from_unixdirs)
        end
        table.insert(finders, _find_package_from_envs)
    end
    if opt.plat == "macosx" or opt.plat == "iphoneos" or opt.plat == "watchos" then
        table.insert(finders, _find_package_from_xcodedirs)
    end

    -- find package
    for _, finder in ipairs(finders) do
        local result = finder(name, links, opt)
        if result ~= nil then
            -- save version
            if version then
                result.version = version
            end
            return result
        end
    end

    -- not found? only add links
    if not result and pkginfo and pkginfo.links then
        return {links = pkginfo.links}
    end
end
