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
-- @author      OpportunityLiu
-- @file        find_cudatool.lua
--

-- imports
import("core.project.config")
import("lib.detect.find_program")
import("lib.detect.find_programver")
import("detect.sdks.find_cuda")

-- find cuda tool
--
-- @param       toolname   name of cuda tool, e.g. "nvcc"
--              parse      default pattern for version string
--              opt        the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local nvcc = find_cudatool("nvcc", "V(%d+%.?%d*%.?%d*.-)%s")
-- local nvcc, version = find_cudatool("nvcc", "V(%d+%.?%d*%.?%d*.-)%s", {program = "nvcc", version = true})
--
-- @endcode
--
function main(toolname, parse, opt)

    -- init options
    opt       = opt or {}
    opt.parse = opt.parse or parse

    -- always keep consistency with cuda cache
    local program
    local toolchains = find_cuda()
    if toolchains and toolchains.bindir then
        program = find_program(path.join(toolchains.bindir, opt.program or toolname), opt)
    end

    -- not found? attempt to find program only
    if not program then
        program = find_program(opt.program or toolname, opt)
    end

    -- find program version
    local version = nil
    if program and opt.version then
        version = find_programver(program, opt)
    end
    return program, version
end
