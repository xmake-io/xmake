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
-- @file        languages.lua
--

-- imports
import(".api_checker")

function main(opt)
    opt = opt or {}
    local values = {
        "ansi", "c89", "c90", "c99", "c11", "c17", "c23", "clatest",
        "cxx98", "cxx03", "cxx11", "cxx14", "cxx17", "cxx1z", "cxx20", "cxx2a", "cxx23", "cxx2b", "cxx2c", "cxx26", "cxxlatest"
    }
    local languages = {}
    for _, value in ipairs(values) do
        table.insert(languages, value)
        if value:find("xx", 1, true) then
            table.insert(languages, (value:gsub("xx", "++")))
        end
        if value:startswith("c") then
            table.insert(languages, "gnu" .. value:sub(2))
        end
    end
    api_checker.check_targets("languages", table.join(opt, {values = languages}))
end
