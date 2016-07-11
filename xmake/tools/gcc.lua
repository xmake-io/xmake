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
-- @file        gcc.lua
--

-- imports
import("core.tool.tool")
import("core.project.config")
import("core.project.project")

-- init it
function init(shellname, kind)
    
    -- save the shell name
    _g.shellname = shellname or "gcc"

    -- save the kind
    _g.kind = kind

    -- init mxflags
    _g.mxflags = {  "-fmessage-length=0"
                ,   "-pipe"
                ,   "-fpascal-strings"
                ,   "\"-DIBOutlet=__attribute__((iboutlet))\""
                ,   "\"-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))\""
                ,   "\"-DIBAction=void)__attribute__((ibaction)\""}

    -- init shflags
    _g.shflags = { "-shared", "-fPIC" }

    -- init cxflags for the kind: shared
    _g.shared         = {}
    _g.shared.cxflags = {"-fPIC"}

    -- init flags map
    _g.mapflags = 
    {
        -- warnings
        ["-W1"] = "-Wall"
    ,   ["-W2"] = "-Wall"
    ,   ["-W3"] = "-Wall"

         -- strip
    ,   ["-s"]  = "-s"
    ,   ["-S"]  = "-S"

    }
end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the define flag
function define(macro)

    -- make it
    return "-D" .. macro:gsub("\"", "\\\"")
end

-- make the undefine flag
function undefine(macro)

    -- make it
    return "-U" .. macro
end

-- make the includedir flag
function includedir(dir)

    -- make it
    return "-I" .. dir
end

-- make the linklib flag
function linklib(lib)

    -- make it
    return "-l" .. lib
end

-- make the linkdir flag
function linkdir(dir)

    -- make it
    return "-L" .. dir
end

-- make the link command
function linkcmd(objectfiles, targetfile, flags)

    -- make it
    return format("%s -o %s %s %s", _g.shellname, targetfile, objectfiles, flags)
end

-- make the complie command
function compcmd(sourcefile, objectfile, flags)

    -- get ccache
    local ccache = nil
    if config.get("ccache") then
        ccache = tool.shellname("ccache")
    end

    -- make it
    local command = format("%s -c %s -o %s %s", _g.shellname, flags, objectfile, sourcefile)
    if ccache then
        command = ccache:append(command, " ")
    end

    -- ok
    return command
end

-- link the target file
function link(objectfiles, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.run(linkcmd(objectfiles, targetfile, flags))
end

-- complie the source file
function compile(sourcefile, objectfile, incdepfile, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.run(compcmd(sourcefile, objectfile, flags))

    -- generate includes file
    if incdepfile then

        -- the temporary file
        local tmpfile = os.tmpfile()

        -- generate it
        os.run(compcmd(sourcefile, tmpfile, (flags or "") .. " -MM"))

        -- translate it
        local results = {}
        local incdeps = io.read(tmpfile)
        for includefile in string.gmatch(incdeps, "%s+([%w/%.%-%+_%$%.]+)") do

            -- save it if belong to the project
            if not path.is_absolute(includefile) then
                table.insert(results, includefile)
            end
        end

        -- update it
        io.save(incdepfile, results)

        -- remove the temporary file
        os.rm(tmpfile)
    end
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local objectfile = path.join(os.tmpdir(), "xmake.gcc.o")
    local sourcefile = path.join(os.tmpdir(), "xmake.gcc.c" .. ifelse(_g.kind == "cxx", "pp", ""))

    -- make stub code
    io.write(sourcefile, "int main(int argc, char** argv)\n{return 0;}")

    -- check it
    os.run("%s -c %s -o %s %s", _g.shellname, ifelse(flags, flags, ""), objectfile, sourcefile)

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
end

