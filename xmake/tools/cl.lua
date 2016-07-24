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
-- @file        cl.lua
--

-- imports
import("core.project.project")

-- init it
function init(shellname)
    
    -- save the shell name
    _g.shellname = shellname or "cl.exe"

    -- init cxflags
    _g.cxflags = { "-nologo", "-Gd", "-MP4", "-D_MBCS", "-D_CRT_SECURE_NO_WARNINGS"}

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
    ,   ["%-fno%-.*"]               = ""

        -- vectorexts
    ,   ["-mmmx"]                   = "-arch:MMX"
    ,   ["-msse"]                   = "-arch:SSE"
    ,   ["-msse2"]                  = "-arch:SSE2"
    ,   ["-msse3"]                  = "-arch:SSE3"
    ,   ["-mssse3"]                 = "-arch:SSSE3"
    ,   ["-mavx"]                   = "-arch:AVX"
    ,   ["-mavx2"]                  = "-arch:AVX2"
    ,   ["-mfpu=.*"]                = ""

        -- language
    ,   ["-ansi"]                   = ""
    ,   ["-std=c99"]                = "-TP" -- compile as c++ files because msvc only support c89
    ,   ["-std=c11"]                = "-TP" -- compile as c++ files because msvc only support c89
    ,   ["-std=gnu99"]              = "-TP" -- compile as c++ files because msvc only support c89
    ,   ["-std=gnu11"]              = "-TP" -- compile as c++ files because msvc only support c89
    ,   ["-std=.*"]                 = ""

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

    -- debug? generate *.pdb file
    if level == "debug" then
        if symbolfile then
            return "-ZI -Fd" .. symbolfile 
        else
            return "-ZI"
        end
    end

    -- none
    return ""
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
        mmx         = "-arch:MMX"
    ,   sse         = "-arch:SSE"
    ,   sse2        = "-arch:SSE2"
    ,   sse3        = "-arch:SSE3"
    ,   ssse3       = "-arch:SSSE3"
    ,   avx         = "-arch:AVX"
    ,   avx2        = "-arch:AVX2"
    }

    -- make it
    return maps[extension] or ""
end

-- make the language flag
function language(stdname)

    -- the stdc maps
    local cmaps = 
    {
        -- stdc
        c99         = "-TP" -- compile as c++ files because msvc only support c89
    ,   gnu99       = "-TP"
    ,   c11         = "-TP"
    ,   gnu11       = "-TP"
    }

    -- select maps
    local maps = cmaps
    if _g.kind == "cxx" or _g.kind == "mxx" then
        maps = {}
    end

    -- make it
    return maps[stdname] or ""
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

    -- generate includes file
    if incdepfile then
        flags = (flags or "") .. " -showIncludes"
    end

    -- compile it
    local outdata = try
    {
        function ()
            return os.iorun(compcmd(sourcefile, objectfile, flags))
        end,
        
        catch
        {
            function (errors)

                -- filter includes notes
                if errors then
                   errors = errors:gsub("Note: including file:%s*.-\r*\n", "")
                end
                os.raise(errors)
            end
        }
    }

    -- parse include dependencies
    if incdepfile and outdata then

        -- translate it
        local results = {}
        local uniques = {}
        for includefile in string.gmatch(outdata, "including file:%s*(.-)\r*\n") do

            -- slower, only for debuging
--            assert(os.isfile(includefile), "invalid include file: %s for %s", includefile, incdepfile)

            -- get the relative
            includefile = path.relative(includefile, project.directory())

            -- save it if belong to the project
            if not path.is_absolute(includefile) then

                -- insert it and filter repeat
                if not uniques[includefile] then
                    table.insert(results, includefile)
                    uniques[includefile] = true
                end
            end
        end

        -- update it
        io.save(incdepfile, results)
    end
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local objectfile = os.tmpfile() .. ".obj"
    local sourcefile = os.tmpfile() .. ".c"
    io.write(sourcefile, "int main(int argc, char** argv)\n{return 0;}")

    -- check it
    os.run("%s -c %s -Fo%s %s", _g.shellname, ifelse(flags, flags, ""), objectfile, sourcefile)

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
end

