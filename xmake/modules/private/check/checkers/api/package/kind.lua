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
-- @author      Shiffted
-- @file        kind.lua
--

import(".api_checker")

function main(opt)
    opt = opt or {}
    api_checker.check_packages("kind", table.join(opt, {check = function(package, value)
        if value == "library" then
            local extraconf = package:extraconf("kind", "library")
            if extraconf then
                if extraconf.headeronly and extraconf.moduleonly then
                    return false, "a library package cannot be set as both 'headeronly' and 'moduleonly'"
                end
                for key, _ in pairs(extraconf) do
                    if key ~= "headeronly" and key ~= "moduleonly" then
                        return false, string.format("unknown kind configuration '%s'", key)
                    end
                end
            end
            return true
        end
        return value == "binary" or value == "toolchain" or value == "template"
    end}))
end
