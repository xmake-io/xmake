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
-- @file        base64.lua
--

-- define module
local sandbox_core_base_base64 = sandbox_core_base_base64 or {}

-- load modules
local base64    = require("base/base64")
local raise     = require("sandbox/modules/raise")

-- decode the base64 string to the data
function sandbox_core_base_base64.decode(base64str, opt)
    local data, errors = base64.decode(base64str, opt)
    if not data and errors then
        raise(errors)
    end
    return data
end

-- encode the data to the base64 string
function sandbox_core_base_base64.encode(data, opt)
    local base64str, errors = base64.encode(data, opt)
    if not base64str and errors then
        raise(errors)
    end
    return base64str
end

-- return module
return sandbox_core_base_base64
