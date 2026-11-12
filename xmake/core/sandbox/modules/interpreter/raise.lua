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
-- @author      OpenAI
-- @file        raise.lua
--

-- load modules
local interpreter = require("base/interpreter")
local string = require("base/string")

function _raise(message, ...)
    local instance = interpreter.instance()
    local scopename = instance:api_interp_get_scopename()
    local errors = string.tryformat(message, ...)
    if scopename then
        errors = string.format("<%s> %s", scopename, errors)
    end
    interpreter._raise(errors)
end

-- load module
return _raise
