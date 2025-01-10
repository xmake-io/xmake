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
-- @file        check_pkgconfig.lua
--

-- imports
import("core.base.option")
import("lib.detect.pkgconfig")

-- check the given pkgconfig file
--
-- @param name      the .pc file name
-- @param opt       the argument options, e.g. { verbose = true, configdirs = {"lib"}}
--
function main(name, opt)
    local result = pkgconfig.libinfo(name, opt)
    if opt.verbose or option.get("verbose") or option.get("diagnosis") then
        cprint("${dim}> checking for pkgconfig/%s.pc", name)
        if result then
            print(result)
        end
    end
    return result
end

