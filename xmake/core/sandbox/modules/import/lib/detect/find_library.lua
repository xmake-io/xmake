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
local find_file         = import("lib.detect.find_file")

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
    local kinds = opt.kind or {"static", "shared"}
    for _, name in ipairs(table.wrap(names)) do
        for _, kind in ipairs(table.wrap(kinds)) do
            local filepath = find_file(target.filename(name, kind, {plat = opt.plat}), paths, opt)
            if opt.plat == "mingw" then
                if not filepath and kind == "shared" then
                    -- for implib/mingw, e.g. libxxx.dll.a
                    filepath = find_file(target.filename(name, kind, {plat = opt.plat}) .. ".a", paths, opt)
                end
                if not filepath then
                    -- in order to be compatible with mingw/windows library with .lib
                    filepath = find_file(target.filename(name, kind, {plat = "windows"}), paths, opt)
                end
            end
            if filepath then
                local filename = path.filename(filepath)
                local linkname = target.linkname(filename, {plat = opt.plat})
                return {kind = kind, filename = filename, linkdir = path.directory(filepath), link = linkname}
            end
        end
    end
end

-- return module
return sandbox_lib_detect_find_library
