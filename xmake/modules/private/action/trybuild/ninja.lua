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
-- @file        ninja.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("lib.detect.find_file")
import("lib.detect.find_tool")

-- detect build-system and configuration file
function detect()
    return find_file("build.ninja", os.curdir())
end

-- do clean
function clean()
    local ninja = assert(find_tool("ninja"), "ninja not found!")
    local ninja_argv = {"-C", os.curdir()}
    if option.get("verbose") or option.get("diagnosis") then
        table.insert(ninja_argv, "-v")
    end
    table.insert(ninja_argv, "-t")
    table.insert(ninja_argv, "clean")
    os.vexecv(ninja.program, ninja_argv)
end

-- do build
function build()
    local ninja = assert(find_tool("ninja"), "ninja not found!")
    local ninja_argv = {"-C", os.curdir()}
    if option.get("verbose") then
        table.insert(ninja_argv, "-v")
    end
    table.insert(ninja_argv, "-j")
    table.insert(ninja_argv, option.get("jobs"))
    os.vexecv(ninja.program, ninja_argv)
    cprint("${color.success}build ok!")
end
