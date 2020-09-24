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
import("lib.detect.find_tool")

-- install package
--
-- @param name  the package name, e.g. pcre2, pcre2/libpcre2-8
-- @param opt   the options, e.g. {verbose = true}
--
-- @return      true or false
--
function main(name, opt)

    -- find brew
    local brew = find_tool("brew")
    if not brew then
        raise("brew not found!")
    end

    -- check architecture
    if opt.arch ~= os.arch() then
        raise("cannot install package(%s) for arch(%s)!", name, opt.arch)
    end

    -- init argv
    local argv = {"install", name:split('/')[1]}
    if opt.verbose or option.get("verbose") then
        table.insert(argv, "--verbose")
    end

    -- install package
    os.vrunv(brew.program, argv)
end
