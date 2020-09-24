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
-- @file        find_libxml2.lua
--

-- imports
import("package.manager.find_package")

-- find libxml2
--
-- @param opt   the package options. e.g. see the options of find_package()
--
-- @return      see the return value of find_package()
--
function main(opt)

    -- find package by the builtin script
    local result = opt.find_package("libxml2", opt)

    -- find package from the homebrew package manager
    if not result and opt.plat == os.host() and opt.arch == os.arch() then
        result = find_package("brew::libxml2/libxml-2.0", opt)
    end

    -- patch "include/libxml2"
    if result then
        local includedirs = {}
        for _, includedir in ipairs(result.includedirs) do
            if includedir:endswith("include") then
                table.insert(includedirs, path.join(includedir, "libxml2"))
            else
                table.insert(includedirs, includedir)
            end
        end
        result.includedirs = includedirs
    end
    return result
end
