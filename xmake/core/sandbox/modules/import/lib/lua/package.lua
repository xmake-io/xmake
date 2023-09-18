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
-- @file        package.lua
--

-- load modules
local string    = require("base/string")
local raise     = require("sandbox/modules/raise")

-- define module
local sandbox_lib_lua_package = sandbox_lib_lua_package or {}

-- load lua module from the dynamic library
--
-- @param libfile       the lib file, e.g. foo.dll, libfoo.so
-- @param symbol        the export symbol name, e.g. luaopen_xxx
--
function sandbox_lib_lua_package.loadlib(libfile, symbol)
    local script, errors = package.loadlib(libfile, symbol)
    if not script then
        raise(errors)
    end
    return script
end

return sandbox_lib_lua_package
