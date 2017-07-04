--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
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
local target            = require("project/target")
local raise             = require("sandbox/modules/raise")
local import            = require("sandbox/modules/import")
local find_file         = import("lib.detect.find_file")

-- get link name from the file name
function sandbox_lib_detect_find_library._link(filename)

    -- get link
    local link, count = filename:gsub(target.filename("([%w_]+)", "static"):gsub("%.", "%%.") .. "$", "%1")
    if count == 0 then
        link, count = filename:gsub(target.filename("([%w_]+)", "shared"):gsub("%.", "%%.") .. "$", "%1")
    end

    -- ok?
    if count > 0 then
        return link
    end
end

-- find library 
--
-- @param names     the library names
-- @param pathes    the search pathes
-- @param opt       the options, .e.g {kind = "static/shared", suffixes = {"/aa", "/bb"}}
--
-- @return          {kind = "static", link = "crypto", linkdir = "/usr/local/lib", filename = "libcrypto.a"}
--
-- @code 
--
-- local library = find_library({"crypto", "cryp*"}, {"/usr/lib", "/usr/local/lib"})
-- local library = find_library(crypto, {"/usr/lib", "/usr/local/lib"}, {kind = "static"})
-- 
-- @endcode
--
function sandbox_lib_detect_find_library.main(names, pathes, opt)

    -- init options
    opt = opt or {}

    -- init kinds
    kinds = opt.kind or {"static", "shared"}

    -- find library file from the given pathes
    for _, name in ipairs(table.wrap(names)) do
        for _, kind in ipairs(table.wrap(kinds)) do
            local filepath = find_file(target.filename(name, kind), pathes, opt)
            if filepath then
                local filename = path.filename(filepath)
                return {kind = kind, filename = filename, linkdir = path.directory(filepath), link = sandbox_lib_detect_find_library._link(filename)}
            end
        end
    end
end

-- return module
return sandbox_lib_detect_find_library
