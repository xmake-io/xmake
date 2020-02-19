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
-- @file        meson.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("lib.detect.find_file")
import("lib.detect.find_tool")

-- get build directory
function _get_buildir()
    return config.buildir() or "build"
end

-- get artifacts directory
function _get_artifacts_dir()
    return path.absolute(path.join(_get_buildir(), "artifacts"))
end

-- detect build-system and configuration file
function detect()
    return find_file("meson.build", os.curdir())
end

-- do clean
function clean()
    local buildir = _get_buildir()
    if os.isdir(buildir) then
    end
end

-- do build
function build()

    -- get artifacts directory
    local artifacts_dir = _get_artifacts_dir()
    if not os.isdir(artifacts_dir) then
        os.mkdir(artifacts_dir)
    end
    os.cd(_get_buildir())

    -- generate makefile
    local meson = assert(find_tool("meson"), "meson not found!")
    local configfile = nil
    if not configfile then
        local argv = {"--prefix=" .. artifacts_dir}
        table.insert(argv, _get_buildir())
        os.execv("meson", argv)
    end

    cprint("output to ${bright}%s", artifacts_dir)
    cprint("${bright}build ok!")
end


