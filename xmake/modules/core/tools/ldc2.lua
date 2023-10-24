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
-- @author      ruki, BarrOff
-- @file        ldc2.lua
--

-- imports
inherit("dmd")
import("core.language.language")

-- init it
function init(self)

    -- init arflags
    self:set("dcarflags", "-lib")

    -- init shflags
    self:set("dcshflags", "-shared", "--relocation-model=pic")

    -- init dcflags for the kind: shared
    self:set("shared.dcflags", "--relocation-model=pic")
end

-- make the optimize flag
function nf_optimize(self, level)
    local maps = {
        none        = "--O0"
    ,   fast        = "--O1"
    ,   faster      = {"--O2", "--release"}
    ,   fastest     = {"--O3", "--release", "--boundscheck=off"}
    ,   smallest    = {"--Oz", "--release", "--boundscheck=off"}
    ,   aggressive  = {"--O4", "--release", "--boundscheck=off"}
    }
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps = _g.symbol_maps
        if not maps then
            maps = {
                debug  = {"-g", "--d-debug"}
            ,   hidden = "-fvisibility=hidden"
            }
            _g.symbol_maps = maps
        end
        return maps[level .. '_' .. kind] or maps[level]
    elseif (kind == "dcld" or kind == "dcsh") and self:is_plat("windows") and level == "debug" then
        return "-g"
    end
end
