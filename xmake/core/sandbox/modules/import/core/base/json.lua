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
-- @file        json.lua
--

-- define module
local sandbox_core_base_json = sandbox_core_base_json or {}

-- load modules
local json      = require("base/json")
local raise     = require("sandbox/modules/raise")

-- inherit some builtin interfaces
sandbox_core_base_json.null               = json.null
sandbox_core_base_json.mark_as_array      = json.mark_as_array
sandbox_core_base_json.is_marked_as_array = json.is_marked_as_array

-- decode the json string to the lua table
function sandbox_core_base_json.decode(jsonstr, opt)
    local luatable, errors = json.decode(jsonstr, opt)
    if not luatable then
        raise(errors)
    end
    return luatable
end

-- encode the lua table to the json string
function sandbox_core_base_json.encode(luatable, opt)
    local jsonstr, errors = json.encode(luatable, opt)
    if not jsonstr then
        raise(errors)
    end
    return jsonstr
end

-- load json file to the lua table
function sandbox_core_base_json.loadfile(filepath, opt)
    local luatable, errors = json.loadfile(filepath, opt)
    if not luatable then
        raise(errors)
    end
    return luatable
end

-- save lua table to the json file
function sandbox_core_base_json.savefile(filepath, luatable, opt)
    local ok, errors = json.savefile(filepath, luatable, opt)
    if not ok then
        raise(errors)
    end
    return ok
end

-- return module
return sandbox_core_base_json
