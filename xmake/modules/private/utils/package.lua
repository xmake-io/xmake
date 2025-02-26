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

-- concat packages, TODO components
function _concat_packages(a, b)
    local result = table.copy(a)
    for k, v in pairs(b) do
        local o = result[k]
        if o ~= nil then
            v = table.join(o, v)
        end
        result[k] = v
    end
    for k, v in pairs(result) do
        if k == "links" or k == "syslinks" or k == "frameworks" or k == "ldflags" or k == "shflags" then
            if type(v) == "table" and #v > 1 then
                -- we need to ensure link orders when removing repeat values
                v = table.reverse_unique(v)
            end
        elseif k == "static" or k == "shared" then
            v = table.unwrap(table.unique(v))
            if type(v) == "table" then
                -- conflict, {true, false}
                v = true
            end
        else
            v = table.unique(v)
        end
        result[k] = v
    end
    return result
end

-- set concat for find_package/fetch info
function fetchinfo_set_concat(fetchinfo)
    if fetchinfo and type(fetchinfo) == "table" then
        debug.setmetatable(fetchinfo, {__concat = _concat_packages})
    end
end
