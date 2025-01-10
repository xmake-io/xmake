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
-- @file        check_importfiles.lua
--

-- imports
import("core.base.option")
import("lib.detect.pkgconfig")

-- check the given importfiles for pkgconfig/cmake
--
-- @param names the import filenames (without .pc/.cmake suffix), e.g. pkgconfig::libxml-2.0, cmake::CURL
-- @param opt   the argument options, e.g. { verbose = true, configdirs = {"lib"}}
--
function main(names, opt)
    for _, name in ipairs(names) do
        local kind
        local parts = name:split("::")
        if #parts == 2 then
            kind = parts[1]
            name = parts[2]
        end
        if kind == nil then
            kind = "pkgconfig"
        end
        if kind == "pkgconfig" then
            local result = pkgconfig.libinfo(name, opt)
            if opt.verbose or option.get("verbose") or option.get("diagnosis") then
                cprint("${dim}> checking for pkgconfig/%s.pc", name)
                if result then
                    print(result)
                end
            end
            if not result then
                return false, string.format("pkgconfig/%s.pc not found!", name)
            end
        end
    end
    return true
end

