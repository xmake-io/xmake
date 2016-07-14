--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.tool.tool")
import("core.project.config")
import("core.project.project")

-- main
function main()

    -- check the doxygen
    local doxygen = tool.check("doxygen", nil, function (shellname)
                        os.run("%s -v", shellname)
                    end)
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
    cprint("${bright}doxygen ok!")
end
