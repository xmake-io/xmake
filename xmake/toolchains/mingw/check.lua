--!A cross-toolchain build utility based on Lua
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
-- @file        check.lua
--

-- imports
import("core.project.config")
import("detect.sdks.find_mingw")

-- check the mingw toolchain
function main(toolchain)
    local mingw = find_mingw(config.get("mingw"), {verbose = true, bindir = config.get("bin"), cross = config.get("cross")})
    if mingw then
        config.set("mingw", mingw.sdkdir, {force = true, readonly = true})
        config.set("cross", mingw.cross, {readonly = true, force = true})
        config.set("bin", mingw.bindir, {readonly = true, force = true})
    else
        -- failed
        cprint("${bright color.error}please run:")
        cprint("    - xmake config --mingw=xxx")
        cprint("or  - xmake global --mingw=xxx")
        raise()
    end
    return true
end
