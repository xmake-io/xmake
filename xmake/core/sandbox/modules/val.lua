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
-- @file        val.lua
--

-- load modules
local sandbox = require("sandbox/sandbox")

-- get the variable value of filter
--
-- e.g.
--
-- local value = val("host")
-- local value = val("env PATH")
-- local value = val("shell echo hello xmake!")
-- local value = val("reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\XXXX;Name")
--
function val(name)

    -- get the current sandbox instance
    local instance = sandbox.instance()
    assert(instance)

    -- get filter from the current sandbox
    local filter = instance:filter()
    if filter then
        return filter:get(name) or ""
    end

    -- no this variable
    return ""
end

-- return module
return val

