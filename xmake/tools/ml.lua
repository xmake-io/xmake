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
-- @file        ml.lua
--

-- init it
function init(shellname)
   
    -- save name
    _g.shellname = shellname or "ml.exe"

    -- init asflags
    _g.asflags = { "-nologo", "-Gd", "-MP4", "-D_MBCS", "-D_CRT_SECURE_NO_WARNINGS"}

    -- init flags map
    _g.mapflags = 
    {
        -- optimize
        ["-O0"]                     = "-Od"
    ,   ["-O3"]                     = "-Ot"
    ,   ["-Ofast"]                  = "-Ox"
    ,   ["-fomit-frame-pointer"]    = "-Oy"

        -- symbols
    ,   ["-g"]                      = "-Z7"
    ,   ["-fvisibility=.*"]         = ""

        -- warnings
    ,   ["-Wall"]                   = "-W3" -- = "-Wall" will enable too more warnings
    ,   ["-W1"]                     = "-W1"
    ,   ["-W2"]                     = "-W2"
    ,   ["-W3"]                     = "-W3"
    ,   ["-Werror"]                 = "-WX"
    ,   ["%-Wno%-error=.*"]         = ""

        -- vectorexts
    ,   ["-mmmx"]                   = "-arch:MMX"
    ,   ["-msse"]                   = "-arch:SSE"
    ,   ["-msse2"]                  = "-arch:SSE2"
    ,   ["-msse3"]                  = "-arch:SSE3"
    ,   ["-mssse3"]                 = "-arch:SSSE3"
    ,   ["-mavx"]                   = "-arch:AVX"
    ,   ["-mavx2"]                  = "-arch:AVX2"
    ,   ["-mfpu=.*"]                = ""

        -- others
    ,   ["-ftrapv"]                 = ""
    ,   ["-fsanitize=address"]      = ""
    }

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the symbol flag
function symbol(level, symbolfile)

    -- check -FS flags
    if _g._FS == nil then
        local ok = try
        {
            function ()
                check("-ZI -FS -Fd" .. os.tmpfile() .. ".pdb")
                return true
            end
        }
        if ok then
            _g._FS = true
        end
    end

    -- debug? generate *.pdb file
    local flags = ""
    if level == "debug" then
        if symbolfile then
            flags = "-ZI -Fd" .. symbolfile 
            if _g._FS then
                flags = "-FS " .. flags
            end
        else
            flags = "-ZI"
        end
    end

    -- none
    return flags
end

-- make the warning flag
function warning(level)

    -- the maps
    local maps = 
    {   
        none        = "-w"
    ,   less        = "-W1"
    ,   more        = "-W3"
    ,   all         = "-W3"
    ,   error       = "-WX"
    }

    -- make it
    return maps[level] or ""
end

-- make the optimize flag
function optimize(level)

    -- the maps
    local maps = 
    {   
        none        = "-Od"
    ,   fast        = "-O1"
    ,   faster      = "-O2"
    ,   fastest     = "-Ot"
    ,   smallest    = "-Os"
    ,   aggressive  = "-Ox"
    }

    -- make it
    return maps[level] or ""
end

-- make the vector extension flag
function vectorext(extension)

    -- the maps
    local maps = 
    {   
        sse         = "-arch:SSE"
    ,   sse2        = "-arch:SSE2"
    ,   avx         = "-arch:AVX"
    ,   avx2        = "-arch:AVX2"
    }

    -- make it
    return maps[extension] or ""
end

-- make the language flag
function language(stdname)
    return ""
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

-- make the complie command
function compcmd(sourcefile, objectfile, flags)

    -- make it
    return format("%s -c %s -Fo%s %s", _g.shellname, flags, objectfile, sourcefile)
end

-- complie the source file
function compile(sourcefile, objectfile, incdepfile, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.run(compcmd(sourcefile, objectfile, flags))
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local objectfile = os.tmpfile() .. ".obj"
    local sourcefile = os.tmpfile() .. ".asm"
    io.write(sourcefile, "end")

    -- check it
    os.run("%s -c %s -Fo%s %s", _g.shellname, ifelse(flags, flags, ""), objectfile, sourcefile)

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
end

