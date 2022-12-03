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
-- @file        main.lua
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

    -- load configuration
    config.load()

    -- enter the environments of doxygen
    local oldenvs = packagenv.enter("llvm")

    -- find clang-format
    local packages = {}
    local clang_format = find_tool("clang-format")
    if not clang_format then
        table.join2(packages, install_packages("llvm"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need force to detect and flush detect cache after loading all environments
    if not clang_format then
        clang_format = find_tool("clang-format", {force = true})
    end
    assert(clang_format, "clang-format not found!")

    -- create style file
    local argv = {}
    local projectdir = project.directory()
    if option.get("create") then
        table.insert(argv, "--style=" .. (option.get("style") or "Google"))
        table.insert(argv, "--dump-config")
        os.execv(clang_format.program, argv, {stdout = path.join(projectdir, ".clang-format"), curdir = projectdir})
        return
    end

    -- set style file
    if option.get("style") then
        table.insert(argv, "--style=" .. option.get("style"))
    end

    -- inplace flag
    table.insert(argv, "-i")

    -- set file to format
    if option.get("files") then
        -- list of files/path to format
        local files = option.get("file"):split(" ")
        for _, f in ipairs(files) do
            local p = path.join(project, f)
            for _, filepath in ipairs(os.files(p)) do
                table.insert(argv, filepath)
            end
        end
    else
        -- format all source files of all targets
        for targetname, target in pairs(project.targets()) do
            -- source files
            for _, source in ipairs(target:sourcefiles()) do
                table.insert(argv, path.join(projectdir, source))
            end
            -- header files
            for _, header in ipairs(target:headerfiles()) do
                table.insert(argv, path.join(projectdir, header))
            end
        end
    end

    -- format files
    os.vrunv(clang_format.program, argv, {curdir = projectdir})
    cprint("${color.success}formatting complete")

    os.setenvs(oldenvs)
end
