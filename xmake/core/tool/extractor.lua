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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        extractor.lua
--

-- define module
local extractor = extractor or {}

-- load modules
local io        = require("base/io")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local config    = require("project/config")
local sandbox   = require("sandbox/sandbox")
local platform  = require("platform/platform")
local tool      = require("tool/tool")

-- get the current tool
function extractor:_tool()
    return self._TOOL
end

-- load the extractor
function extractor.load()

    -- get it directly from cache dirst
    if extractor._INSTANCE then
        return extractor._INSTANCE
    end

    -- new instance
    local instance = table.inherit(extractor)

    -- load the extractor tool
    local result, errors = tool.load("ex")
    if not result then
        return nil, errors
    end

    -- save tool
    instance._TOOL = result

    -- save this instance
    extractor._INSTANCE = instance

    -- ok
    return instance
end

-- get properties of the tool
function extractor:get(name)
    return self:_tool():get(name)
end

-- extract the library file
function extractor:extract(libraryfile, objectdir)
    return sandbox.load(self:_tool().extract, self:_tool(), libraryfile, objectdir)
end

-- return module
return extractor
