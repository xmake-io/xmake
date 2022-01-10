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
-- @file        find_glslc.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")
import("core.tool.toolchain")

-- find glslc
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local glslc = find_glslc()
-- local glslc, version = find_glslc({program = "glslc", version = true})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- find program
    local program = find_program(opt.program or "glslc", opt)
    if not program and is_plat("android") then
        local ndk = toolchain.load("ndk"):config("ndk")
        if ndk then
            local prebuilt = (is_host("macosx") and "darwin" or os.host()) .. "-x86_64"
            opt.paths = path.join(ndk, "shader-tools", prebuilt)
            program = find_program(opt.program or "glslc", opt)
        end
    end

    -- find program version
    local version = nil
    if program and opt.version then
        version = find_programver(program, opt)
    end
    return program, version
end
