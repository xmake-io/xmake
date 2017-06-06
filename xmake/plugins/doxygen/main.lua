--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("detect.tool.find_doxygen")

-- main
function main()

    -- find doxygen
    local doxygen = find_doxygen()
    assert(doxygen, "doxygen not found!")

    -- generate doxyfile first
    local doxyfile = path.join(os.tmpdir(), "doxyfile")

    -- generate the default doxyfile
    os.run("%s -g %s", doxygen, doxyfile)

    -- load configure
    config.load()

    -- load project
    project.load()

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
    local outputdir = option.get("outputdir") or config.get("buildir") or "build"
    if outputdir then

        -- update the doxyfile
        io.gsub(doxyfile, "OUTPUT_DIRECTORY%s-=.-\n", format("OUTPUT_DIRECTORY = %s\n", outputdir))

        -- ensure the output directory
        os.mkdir(outputdir)
    end

    -- set the project version
    --
    -- PROJECT_NUMBER = 
    --
    local version = project.version()
    if version then
        io.gsub(doxyfile, "PROJECT_NUMBER%s-=.-\n", format("PROJECT_NUMBER = %s\n", version))
    end

    -- set the project name
    --
    -- PROJECT_NAME = 
    --
    local name = project.name()
    if name then
        io.gsub(doxyfile, "PROJECT_NAME%s-=.-\n", format("PROJECT_NAME = %s\n", name))
    end

    -- check
    assert(os.isfile(doxyfile), "%s not found!", doxyfile)

    -- enter the project directory
    os.cd(project.directory())

    -- trace
    cprint("generating ..${beer}")

    -- generate document
    if option.get("verbose") then
        os.exec("%s %s", doxygen, doxyfile)
    else
        os.run("%s %s", doxygen, doxyfile)
    end

    -- leave the project directory
    os.cd("-")

    -- trace
    cprint("${bright green}result: ${default green}%s/html/index.html", outputdir)
    cprint("${bright}doxygen ok!${ok_hand}")
end
