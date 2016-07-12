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
        ["-s"]                  = ""
    ,   ["-S"]                  = ""
 
        -- others
    ,   ["-ftrapv"]             = ""
    ,   ["-fsanitize=address"]  = ""
    }
end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the linklib flag
function linklib(lib)

    -- make it
    return lib .. ".lib"
end

-- make the linkdir flag
function linkdir(dir)

    -- make it
    return "-libpath:" .. dir
end

-- make the link command
function linkcmd(objectfiles, targetfile, flags)

    -- make it
    local cmd = format("%s %s -out:%s %s", _g.shellname, flags, targetfile, objectfiles)

    -- too long?
    if #cmd > 4096 then
        local argfile = targetfile .. ".arg"
        io.printf(argfile, "%s -out:%s %s", flags, targetfile, objectfiles)
        cmd = format("%s @%s", _g.shellname, argfile)
    end

    -- ok?
    return cmd
end

-- link the target file
function link(objectfiles, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.run(linkcmd(objectfiles, targetfile, flags))
end

-- make the archive command
function archivecmd(objectfiles, targetfile, flags)
    return linkcmd(objectfiles, targetfile, flags)
end

-- archive the library file
function archive(objectfiles, targetfile, flags)
    link(objectfiles, targetfile, flags)
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local binaryfile = os.tmpfile() .. ".exe"
    local objectfile = os.tmpfile() .. ".obj"
    local sourcefile = os.tmpfile() .. ".c"

    -- main entry
    if flags and flags:lower():find("subsystem:windows") then
        io.write(sourcefile, "int WinMain(void* instance, void* previnst, char** argv, int argc)\n{return 0;}")
    else
        io.write(sourcefile, "int main(int argc, char** argv)\n{return 0;}")
    end

    -- check it
    os.run("cl -c -Fo%s %s", objectfile, sourcefile)
    os.run("%s %s -out:%s %s", _g.shellname, ifelse(flags, flags, ""), binaryfile, objectfile)

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
    os.rm(binaryfile)
end

