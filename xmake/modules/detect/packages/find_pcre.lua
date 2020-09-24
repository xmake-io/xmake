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
-- @file        find_pcre.lua
--

-- imports
import("package.manager.find_package")

-- find pcre
--
-- @param opt   the package options. e.g. see the options of find_package()
--
-- @return      see the return value of find_package()
--
function main(opt)

    -- find package by the builtin script
    local result = opt.find_package("pcre", opt)

    -- find package from the homebrew package manager
    if not result and opt.plat == os.host() and opt.arch == os.arch() then
        for _, width in ipairs({"", "16", "32"}) do
            result = find_package("brew::pcre/libpcre" .. width, opt)
            if result then
                break
            end
        end
    end
    return result
end
