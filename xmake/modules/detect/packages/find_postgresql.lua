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
-- @file        find_postgresql.lua
--

-- imports
import("lib.detect.find_path")
import("lib.detect.find_library")

-- find postgresql
--
-- @param opt   the package options. e.g. see the options of find_package()
--
-- @return      see the return value of find_package()
--
function main(opt)

    -- init search paths
    local paths = {"$(env PostgreSQL_ROOT)"}
    if opt.plat == "windows" then
        local regs = winos.registry_keys("HKEY_LOCAL_MACHINE\\SOFTWARE\\PostgreSQL\\Installations\\postgresql-x64-*")
        for _, reg in ipairs(regs) do
            table.insert(paths, winos.registry_query(reg .. ";Base Directory"))
        end
    elseif opt.plat == "macosx" then
        table.insert(paths, "/Library/PostgreSQL")
    else
        table.insert(paths, "/usr/local/pgsql")
    end

    local result = {links = {}, linkdirs = {}, includedirs = {}, libfiles = {}}
    
    -- find library
    local libname = (opt.plat == "windows" and "libpq" or "pq")
    local linkinfo = find_library(libname, paths, {suffixes = "lib"})
    if linkinfo then
        table.insert(result.linkdirs, linkinfo.linkdir)
        table.insert(result.links, libname)
        if opt.plat == "windows" then
            table.insert(result.libfiles, path.join(linkinfo.linkdir, "libpq.lib"))
            table.insert(result.libfiles, path.join(linkinfo.linkdir, "libpq.dll"))
        end
    end

    -- find headers
    local path = find_path("libpq-fe.h", paths, {suffixes = "include"})
    if path then
        table.insert(result.includedirs, path)
    end
    path = find_path("postgres.h", paths, {suffixes = "include/server"})
    if path then
        table.insert(result.includedirs, path)
    end

    -- ok?
    if #result.includedirs > 0 and #result.linkdirs > 0 then
        return result
    end
end
