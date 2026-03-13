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
-- @author      ruki
-- @file        utils.lua
--

-- define module
local utils = utils or {}

-- check if a package (with optional features) is installed for the given triplet
-- e.g. is_installed(vcpkg, "curl", "x64-windows-static-md")
--      is_installed(vcpkg, "curl[mbedtls]", "x64-windows-static-md")
--
-- @see https://github.com/xmake-io/xmake/issues/7388
--
function utils.is_installed(vcpkg, name, triplet)
    local listinfo = try { function ()
        return os.iorunv(vcpkg, {"list", name .. ":" .. triplet, "--x-full-desc"})
    end}
    if listinfo then
        local exact_prefix = name .. ":" .. triplet
        for _, line in ipairs(listinfo:split("\n", {plain = true})) do
            if line:startswith(exact_prefix) then
                return true
            end
        end
    end
    return false
end

-- return module
return utils
