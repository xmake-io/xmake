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
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("lib.detect.find_tool")

-- install package
--
-- e.g.
-- add_requires("nimble::zip")
-- add_requires("nimble::zip >0.3")
-- add_requires("nimble::zip 0.3.1")
--
-- @param name  the package name, e.g. nimble::zip
-- @param opt   the options, e.g. { verbose = true, mode = "release", plat = , arch = , require_version = "x.x.x"}
--
-- @return      true or false
--
function main(name, opt)

    -- find nimble
    local nimble = find_tool("nimble")
    if not nimble then
        raise("nimble not found!")
    end

    -- install the given package
    local argv = {"install", "-y"}
    if option.get("verbose") then
        table.insert(argv, "--verbose")
    end
    local require_str = name
    if opt.require_version and opt.require_version ~= "latest" and opt.require_version ~= "master" then
        name = name .. "@"
        name = name .. opt.require_version
    end
    table.insert(argv, name)
    os.vrunv(nimble.program, argv)
end
