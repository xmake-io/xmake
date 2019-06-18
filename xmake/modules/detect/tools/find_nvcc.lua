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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_nvcc.lua
--

-- imports
import("core.project.config")
import("lib.detect.find_program")
import("lib.detect.find_programver")
import("detect.sdks.find_cuda")

-- find nvcc 
--
-- @param opt   the argument options, .e.g {version = true}
--
-- @return      program, version
--
-- @code 
--
-- local nvcc = find_nvcc()
-- local nvcc, version = find_nvcc({program = "nvcc", version = true})
-- 
-- @endcode
--
function main(opt)

    -- init options
    opt       = opt or {}
    opt.parse = opt.parse or "V(%d+%.?%d*%.?%d*.-)%s"

    local program = nil

    -- find program
    if opt.program then
        program = find_program(opt.program, opt)
    end

    -- not found? attempt to find program from cuda toolchains
    if not program then
        local toolchains = find_cuda(config.get("cuda"))
        if toolchains and toolchains.bindir then
            program = find_program(path.join(toolchains.bindir, "nvcc"), opt)
        end
    end

    -- not found? attempt to find program from PATH
    if not program then
        program = find_program("nvcc", opt)
    end

    -- find program version
    local version = nil
    if program and opt.version then
        version = find_programver(program, opt)
    end

    -- ok?
    return program, version
end
