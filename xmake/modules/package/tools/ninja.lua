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
-- @file        ninja.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- build package
function build(package, configs, opt)
    opt = opt or {}
    local buildir = opt.buildir or os.curdir()
    local njob = opt.jobs or option.get("jobs") or tostring(os.default_njob())
    local ninja = assert(find_tool("ninja"), "ninja not found!")
    local argv = {}
    if opt.target then
        table.insert(argv, opt.target)
    end
    table.insert(argv, "-C")
    table.insert(argv, buildir)
    if option.get("diagnosis") then
        table.insert(argv, "-v")
    end
    table.insert(argv, "-j")
    table.insert(argv, njob)
    if configs then
        table.join2(argv, configs)
    end
    os.vrunv(ninja.program, argv, {envs = opt.envs})
end

-- install package
function install(package, configs, opt)
    opt = opt or {}
    local buildir = opt.buildir or os.curdir()
    local njob = opt.jobs or option.get("jobs") or tostring(os.default_njob())
    local ninja = assert(find_tool("ninja"), "ninja not found!")
    local argv = {"install"}
    if opt.target then
        table.insert(argv, opt.target)
    end
    table.insert(argv, "-C")
    table.insert(argv, buildir)
    if option.get("verbose") then
        table.insert(argv, "-v")
    end
    table.insert(argv, "-j")
    table.insert(argv, njob)
    if configs then
        table.join2(argv, configs)
    end
    os.vrunv(ninja.program, argv, {envs = opt.envs})
end
