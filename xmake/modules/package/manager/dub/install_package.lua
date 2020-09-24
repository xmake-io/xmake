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
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("lib.detect.find_tool")

-- install package
--
-- @param name  the package name, e.g. dub::log
-- @param opt   the options, e.g. { verbose = true, mode = "release", plat = , arch = , version = "x.x.x", buildhash = "xxxxxx"}
--
-- @return      true or false
--
function main(name, opt)

    -- find dub
    local dub = find_tool("dub")
    if not dub then
        raise("dub not found!")
    end

    -- fetch the given package
    local argv = {"fetch", name}
    if option.get("verbose") then
        table.insert(argv, "-v")
    end
    if opt.version and opt.version ~= "latest" and opt.version ~= "master" then
        table.insert(argv, "--version=" .. opt.version)
    end
    os.vrunv(dub.program, argv)

    -- build the given package
    argv = {"build", name, "-y"}
    if opt.mode == "debug" then
        table.insert(argv, "--build=debug")
    else
        table.insert(argv, "--build=release")
    end
    if option.get("verbose") then
        table.insert(argv, "-v")
    end
    local archs = {x86_64          = "x86_64",
                   x64             = "x86_64",
                   i386            = "x86",
                   x86             = "x86"}
    local arch = archs[opt.arch]
    if arch then
        table.insert(argv, "--arch=" .. arch)
    else
        raise("cannot install package(%s) for arch(%s)!", name, opt.arch)
    end
    os.vrunv(dub.program, argv)
end
