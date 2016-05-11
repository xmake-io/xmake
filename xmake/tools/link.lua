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
-- @file        link.lua
--

-- imports
import("core.project.config")

-- init it
function init(shellname)
    
    -- save the shell name
    _g.shellname = shellname or "link.exe"

    -- the architecture
    local arch = config.get("arch")

    -- init flags for architecture
    local flags_arch = ""
    if arch == "x86" then 
        flags_arch = "-machine:x86"
    elseif arch == "x64" or arch == "amd64" or arch == "x86_amd64" then
        flags_arch = "-machine:x64"
    end

    -- init ldflags
    _g.ldflags = { "-nologo", "-dynamicbase", "-nxcompat", flags_arch}

    -- init arflags
    _g.arflags = {"-nologo", flags_arch}

    -- init shflags
    _g.shflags = {"-nologo", flags_arch}

    -- init flags map
    _g.mapflags = 
    {
        -- strip
        ["-s"]                     = ""
    ,   ["-S"]                     = ""
 
        -- others
    ,   ["-ftrapv"]                = ""
    ,   ["-fsanitize=address"]     = ""
    }
end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the link flag
function link(lib)

    -- make it
    return lib .. ".lib"
end

-- make the linkdir flag
function linkdir(dir)

    -- make it
    return "-libpath:" .. dir
end

-- make the link command
function linkcmd(objfiles, targetfile, flags)

    -- make it
    local cmd = format("%s %s -out:%s %s", _g.shellname, flags, targetfile, objfiles)

    -- too long?
    if #cmd > 4096 then
        local argfile = targetfile .. ".arg"
        io.printf(argfile, "%s -out:%s %s", flags, targetfile, objfiles)
        cmd = format("%s @%s", _g.shellname, argfile)
    end

    -- ok?
    return cmd
end

-- run command
function run(...)

    -- run it
    os.run(...)
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local exefile = path.join(os.tmpdir(), "xmake.cl.exe")
    local objfile = path.join(os.tmpdir(), "xmake.cl.obj")
    local srcfile = path.join(os.tmpdir(), "xmake.cl.c")
    io.write(srcfile, "int main(int argc, char** argv)\n{return 0;}")

    -- check it
    os.run("cl -c -Fo%s %s", objfile, srcfile)
    os.run("%s %s -out:%s %s", _g.shellname, ifelse(flags, flags, ""), exefile, objfile)

    -- remove files
    os.rm(objfile)
    os.rm(srcfile)
    os.rm(exefile)
end

