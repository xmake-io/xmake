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
-- @file        find_package.lua
--

-- imports
import("lib.detect.find_path")
import("lib.detect.find_library")
import("lib.detect.pkg_config")

-- find package from the system directories
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)
       
    -- only support the current host platform and architecture
    if opt.plat ~= os.host() or opt.arch ~= os.arch() then
        return
    end

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

    -- attempt to get links from pkg-config
    local pkginfo = nil
    local version = nil
    local links = table.wrap(opt.links)
    if #links == 0 then
        pkginfo = pkg_config.libinfo(name)
        if pkginfo then
            links = table.wrap(pkginfo.links)
            version = pkginfo.version
        end
    end

    -- uses name as links directly e.g. libname.a
    if #links == 0 then
        links = table.wrap(name)
    end

    -- find library 
    local result = nil
    for _, link in ipairs(links) do
        local libinfo = find_library(link, linkdirs)
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

    -- not found? only add links
    if not result and pkginfo and pkginfo.links then
        result = {links = pkginfo.links}
    end

    -- save version
    if result and version then
        result.version = version
    end

    -- ok
    return result
end
