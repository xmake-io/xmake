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
-- @file        bcsave.lua
--

-- load modules
local io        = require("base/io")
local string    = require("base/string")
local raise     = require("sandbox/modules/raise")

-- save lua file to bitcode file
--
-- @param luafile       the lua file
-- @param bcfile        the bitcode file
-- @param opt           the arguments option, e.g. {strip = true, displaypath = "/xxx/a.lua", nocache = true}
--
function main(luafile, bcfile, opt)
    opt = opt or {}
    local result, errors = loadfile(luafile, "bt", {displaypath = opt.displaypath, nocache = opt.nocache})
    if not result then
        raise(errors)
    end
    result, errors = string._dump(result, opt.strip)
    if not result then
        raise(errors)
    end
    result, errors = io.writefile(bcfile, result)
    if not result then
        raise(errors)
    end
end
return main
