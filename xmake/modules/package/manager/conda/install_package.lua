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
-- @param name  the package name, e.g. conda::libpng 1.6.37
-- @param opt   the options, e.g. { verbose = true }
--
-- @return      true or false
--
function main(name, opt)

    -- check
    opt = opt or {}
    assert(is_host(opt.plat) and os.arch() == opt.arch, "conda cannot install %s for %s/%s", name, opt.plat, opt.arch)

    -- find conda
    local conda = find_tool("conda")
    if not conda then
        raise("conda not found!")
    end

    -- install package
    local argv = {"install", "-y"}
    if option.get("verbose") then
        table.insert(argv, "-v")
    end
    if opt.require_version and opt.require_version:find('.', 1, true) then
        name = name .. "=" .. opt.require_version
    end
    table.insert(argv, name)
    os.vrunv(conda.program, argv)
end
