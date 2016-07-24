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
-- @file        swiftc.lua
--

-- imports
import("core.tool.tool")
import("core.project.config")

-- init it
function init(shellname)
    
    -- save the shell name
    _g.shellname = shellname or "swiftc"

    -- init flags map
    _g.mapflags = 
    {
        -- symbols
        ["-fvisibility=hidden"]     = ""

        -- warnings
    ,   ["-w"]                      = ""
    ,   ["-W.*"]                    = ""

        -- optimize
    ,   ["-O0"]                     = "-Onone"
    ,   ["-Ofast"]                  = "-Ounchecked"
    ,   ["-O.*"]                    = "-O"

        -- vectorexts
    ,   ["-m.*"]                    = ""

        -- strip
    ,   ["-s"]                      = ""
    ,   ["-S"]                      = ""

        -- others
    ,   ["-ftrapv"]                 = ""
    ,   ["-fsanitize=address"]      = ""
    }

end

-- get the property
function get(name)

    -- init ldflags
    if not _g.ldflags then
        local swift_linkdirs = config.get("__swift_linkdirs")
        if swift_linkdirs then
            _g.ldflags = { "-L" .. swift_linkdirs }
        end
    end

    -- get it
    return _g[name]
end

-- make the symbol flag
function symbol(level, symbolfile)

    -- the maps
    local maps = 
    {   
        debug       = "-g"
    }

    -- make it
    return maps[level] or ""
end

-- make the warning flag
function warning(level)

    -- the maps
    local maps = 
    {   
        none        = "-w"
    ,   less        = "-W1"
    ,   more        = "-W3"
    ,   all         = "-Wall"
    ,   error       = "-Werror"
    }

    -- make it
    return maps[level] or ""
end

-- make the optimize flag
function optimize(level)

    -- the maps
    local maps = 
    {   
        none        = "-Onone"
    ,   fast        = "-O"
    ,   faster      = "-O"
    ,   fastest     = "-O"
    ,   smallest    = "-O"
    ,   aggressive  = "-Ounchecked"
    }

    -- make it
    return maps[level] or ""
end

-- make the vector extension flag
function vectorext(extension)

    -- the maps
    local maps = 
    {   
        mmx         = "-mmmx"
    ,   sse         = "-msse"
    ,   sse2        = "-msse2"
    ,   sse3        = "-msse3"
    ,   ssse3       = "-mssse3"
    ,   avx         = "-mavx"
    ,   avx2        = "-mavx2"
    ,   neon        = "-mfpu=neon"
    }

    -- make it
    return maps[extension] or ""
end

-- make the language flag
function language(stdname)
    return ""
end

-- make the compile command
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

-- complie the source file
function compile(sourcefile, objectfile, incdepfile, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.run(compcmd(sourcefile, objectfile, flags))
end

-- make the includedir flag
function includedir(dir)

    -- make it
    return "-Xcc -I" .. dir
end

-- make the define flag
function define(macro)

    -- make it
    return "-Xcc -D" .. macro:gsub("\"", "\\\"")
end

-- make the undefine flag
function undefine(macro)

    -- make it
    return "-Xcc -U" .. macro
end

-- check the given flags 
function check(flags)

    -- check it
    os.run("%s -h", _g.shellname)
end
