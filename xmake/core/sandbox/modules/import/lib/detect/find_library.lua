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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        find_library.lua
--

-- define module
local sandbox_lib_detect_find_library = sandbox_lib_detect_find_library or {}

-- load modules
local os                = require("base/os")
local path              = require("base/path")
local utils             = require("base/utils")
local table             = require("base/table")
local config            = require("project/config")
local target            = require("project/target")
local raise             = require("sandbox/modules/raise")
local import            = require("sandbox/modules/import")
local xmake             = require("base/xmake")
local find_file         = import("lib.detect.find_file")

-- find library from directories list
function sandbox_lib_detect_find_library._find_from_directories(names, directories, kinds, suffixes, opt)
    names = table.wrap(names)
    directories = table.wrap(directories)
    kinds = table.wrap(kinds)
    suffixes = table.wrap(suffixes)
    if #kinds == 0 then
        kinds = {"static", "shared"}
    end
    opt = opt or {}
    local plat = opt.plat
    for _, name in ipairs(names) do
        for _, kind in ipairs(kinds) do
            local filename = target.filename(name, kind, {plat = plat})
            local filepath = find_file._find_from_directories(filename, directories, suffixes)
            if plat == "mingw" then
                if not filepath and kind == "shared" then
                    filepath = find_file._find_from_directories(filename .. ".a", directories, suffixes)
                end
                if not filepath then
                    filepath = find_file._find_from_directories(target.filename(name, kind, {plat = "windows"}), directories, suffixes)
                end
            end
            if filepath then
                local linkname = target.linkname(path.filename(filepath), {plat = plat})
                return {kind = kind, filename = path.filename(filepath), linkdir = path.directory(filepath), link = linkname}
            end
        end
    end
end

-- find library
--
-- @param names     the library names
-- @param paths     the search paths
-- @param opt       the options, e.g. {kind = "static/shared", suffixes = {"/aa", "/bb"}}
--
-- @return          {kind = "static", link = "crypto", linkdir = "/usr/local/lib", filename = "libcrypto.a", plat = ..}
--
-- @code
--
-- local library = find_library({"crypto", "cryp*"}, {"/usr/lib", "/usr/local/lib"})
-- local library = find_library("crypto", {"/usr/lib", "/usr/local/lib"}, {kind = "static"})
--
-- @endcode
--
function sandbox_lib_detect_find_library.main(names, paths, opt)

    -- no paths?
    if not paths or #paths == 0 then
        return
    end

    -- find library file from the given paths
    opt = opt or {}
    local directories = find_file._expand_paths(paths)
    local suffixes = find_file._normalize_suffixes(opt.suffixes)
    local kinds = table.wrap(opt.kind or {"static", "shared"})

    if opt.async and xmake.in_main_thread() then
        local result, _ = os._async_task().find_library(names, directories, kinds, {suffixes = suffixes, plat = opt.plat})
        return result
    end

    return sandbox_lib_detect_find_library._find_from_directories(names, directories, kinds, suffixes, {plat = opt.plat})
end

-- return module
return sandbox_lib_detect_find_library
