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
-- @file        get_package_name.lua
--

function main(name, opt)
    opt = opt or {}
    local configs = opt.configs or {}

    -- https://www.msys2.org/docs/package-naming/
    if is_subhost("msys") then
        local msystem = configs.msystem
        if not msystem and opt.plat == "mingw" then
            msystem = "mingw"
        end
        if msystem == "mingw" or msystem == "ucrt" or msystem == "clang" then
            local prefix = "mingw-w64-"
            local arch = opt.arch
            if arch == "x86" or arch == "i386" then
                arch = "i686"
            elseif arch == "x64" then
                arch = "x86_64"
            elseif arch == "arm64" then
                arch = "aarch64"
            end
            if msystem ~= "mingw" then
                name = prefix .. msystem .. "-" .. arch .. "-" .. name
            else
                name = prefix .. arch .. "-" .. name
            end
        else
            -- msys packages, no prefix
        end
    end
    return name
end

