--!The Automatic Cross-platform Build Tool
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

-- main
function main()

    -- check the doxygen
    local doxygen = tool.check("doxygen", function (shellname)
                        os.run("%s -v", shellname)
                    end)
    assert(doxygen, "doxygen not found!")

    -- generate doxyfile first if not exists
    local doxyfile = option.get("doxyfile")
    if not os.isfile(doxyfile) then

        -- generate the default doxyfile
        os.run("%s -g %s", doxygen, doxyfile)

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
        -- HTML_OUTPUT  = html
        -- LATEX_OUTPUT = latex
        --
        local outputdir = option.get("outputdir")
        if outputdir then

            -- update the doxyfile
            io.gsub(doxyfile, "HTML_OUTPUT%s-=.-\n", format("HTML_OUTPUT = %s/html\n", outputdir))
            io.gsub(doxyfile, "LATEX_OUTPUT%s-=.-\n", format("LATEX_OUTPUT = %s/latex\n", outputdir))

            -- ensure the output directory
            os.mkdir(outputdir)
        end
    end

    -- check
    assert(os.isfile(doxyfile), "%s not found!", doxyfile)

    -- generate document
    os.run("%s %s", doxygen, doxyfile)

    -- trace
    print("doxygen ok!")
end
