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

-- generate doxyfile
function _generate_doxyfile()

    -- generate the default doxyfile
    local doxyfile = path.join(project.directory(), "doxyfile")
    os.vrunv(doxygen.program, {"-g", doxyfile})

    -- enable recursive
    --
    -- RECURSIVE = YES
    --
    io.gsub(doxyfile, "RECURSIVE%s-=%s-NO", "RECURSIVE = YES")

    -- set the source directory
    --
    -- INPUT = xxx
    --
    local srcdir = option.get("srcdir")
    if srcdir and os.isdir(srcdir) then
        io.gsub(doxyfile, "INPUT%s-=.-\n", format("INPUT = %s\n", srcdir))
    end

    -- set the output directory
    --
    -- OUTPUT_DIRECTORY =
    --
    local outputdir = option.get("outputdir") or config.buildir()
    if outputdir then
        io.gsub(doxyfile, "OUTPUT_DIRECTORY%s-=.-\n", format("OUTPUT_DIRECTORY = %s\n", outputdir))
        os.mkdir(outputdir)
    end

    -- set the project name
    --
    -- PROJECT_NAME =
    --
    local name = project.name()
    if name then
        io.gsub(doxyfile, "PROJECT_NAME%s-=.-\n", format("PROJECT_NAME = %s\n", name))
    end
    return doxyfile
end

function main()

    -- load configuration
    config.load()

    -- enter the environments of doxygen
    local oldenvs = packagenv.enter("doxygen")

    -- find doxygen
    local packages = {}
    local doxygen = find_tool("doxygen")
    if not doxygen then
        table.join2(packages, install_packages("doxygen"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need force to detect and flush detect cache after loading all environments
    if not doxygen then
        doxygen = find_tool("doxygen", {force = true})
    end
    assert(doxygen, "doxygen not found!")

    -- get doxyfile first
    local doxyfile = "doxyfile"
    if not os.isfile(doxyfile) then
        doxyfile = _generate_doxyfile()
    end
    assert(os.isfile(doxyfile), "%s not found!", doxyfile)

    -- set the project version
    --
    -- PROJECT_NUMBER =
    --
    local version = project.version()
    if version then
        io.gsub(doxyfile, "PROJECT_NUMBER%s-=.-\n", format("PROJECT_NUMBER = %s\n", version))
    end

    -- generate document
    cprint("generating ..${beer}")
    os.vrunv(doxygen.program, {doxyfile}, {curdir = project.directory()})

    -- done
    cprint("${bright green}result: ${default green}%s/html/index.html", outputdir)
    cprint("${color.success}doxygen ok!")
    os.setenvs(oldenvs)
end
