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
-- @file        tidy.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("lib.detect.find_tool")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")

-- main
function main()

    -- enter the environments of llvm
    local oldenvs = packagenv.enter("llvm")

    -- find clang-tidy
    local packages = {}
    local clang_tidy = find_tool("clang-tidy")
    if not clang_tidy then
        table.join2(packages, install_packages("llvm"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need force to detect and flush detect cache after loading all environments
    if not clang_tidy then
        clang_tidy = find_tool("clang-tidy", {force = true})
    end
    assert(clang_tidy, "clang-tidy not found!")

    -- do clang-tidy
    os.execv(clang_tidy.program, {"--version"})

    -- done
    os.setenvs(oldenvs)
end

