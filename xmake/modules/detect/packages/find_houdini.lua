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
-- @author      xq114
-- @file        find_houdini.lua
--

-- imports
import("lib.detect.find_path")
import("lib.detect.find_library")

-- find houdini
--
-- @param opt   the package options. e.g. see the options of find_package()
--
-- @return      see the return value of find_package()
--
function main(opt)

    -- init search paths
    local paths = {"$(env Houdini_ROOT)"}
    if opt.plat == "windows" then
        local keys = winos.registry_keys("HKEY_LOCAL_MACHINE\\SOFTWARE\\Side Effects Software\\Houdini *.*.*")
        for _, key in ipairs(keys) do
            table.insert(paths, winos.registry_query(key .. ";InstallPath"))
        end
    elseif opt.plat == "macosx" then
        for _, path in ipairs(os.dirs("/Applications/Houdini/Houdini*.*.*")) do
            table.insert(paths, path)
        end
    else
        for _, path in ipairs(os.dirs("/opt/hfs*.*.*")) do
            table.insert(paths, path)
        end
    end

    -- find sdkdir
    local result = {sdkdir = nil, links = {}, linkdirs = {}, includedirs = {}, libfiles = {}}
    result.sdkdir = find_path("houdini_setup", paths)
    if not result.sdkdir then
        return
    end
    
    -- find library
    local prefix = (opt.plat == "windows" and "lib" or "")
    local libs = {"HAPI"}
    for _, lib in ipairs(libs) do
        local libname = prefix .. lib
        local linkinfo = find_library(libname, {result.sdkdir}, {suffixes = "custom/houdini/dsolib"})
        if linkinfo then
            table.insert(result.linkdirs, linkinfo.linkdir)
            table.insert(result.links, libname)
            if opt.plat == "windows" then
                table.insert(result.libfiles, path.join(linkinfo.linkdir, libname .. ".lib"))
                table.insert(result.libfiles, path.join(result.sdkdir, "bin", libname .. ".dll"))
            end
        end
    end

    -- find headers
    local path = find_path(path.join("HAPI", "HAPI.h"), {result.sdkdir}, {suffixes = path.join("toolkit", "include")})
    if path then
        table.insert(result.includedirs, path)
    end

    -- ok?
    if #result.includedirs > 0 and #result.linkdirs > 0 then
        return result
    end
end
