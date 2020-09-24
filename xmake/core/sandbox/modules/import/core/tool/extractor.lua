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
local sandbox_core_tool_extractor = sandbox_core_tool_extractor or {}

-- load modules
local platform  = require("platform/platform")
local extractor = require("tool/extractor")
local raise     = require("sandbox/modules/raise")

-- extract library file
function sandbox_core_tool_extractor.extract(libraryfile, objectdir)

    -- get the extractor instance
    local instance, errors = extractor.load()
    if not instance then
        raise(errors)
    end

    -- extract it
    local ok, errors = instance:extract(libraryfile, objectdir)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_tool_extractor
