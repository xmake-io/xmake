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
-- @file        iccarm.lua
--

inherit("gcc")

-- make the symbol flag
function nf_symbol(self, level)
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps = _g.symbol_maps
        if not maps then
            maps = {
                debug  = "-g"
            }
            _g.symbol_maps = maps
        end
        return maps[level .. '_' .. kind] or maps[level]
    elseif kind == "ld" or kind == "sh" then
        local plat = self:plat()
        if level == "debug" and is_host("windows") then
            return "-g"
        end
    end
end

