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
-- @file        cl.lua
--

-- imports
import("core.project.project")

-- init it
function init(self)
    
    -- init cxflags
    _g.cxflags = { "-nologo", "-Gd", "-MP4", "-D_MBCS", "-D_CRT_SECURE_NO_WARNINGS"}

    -- init flags map
    _g.mapflags = 
    {
        -- optimize
        ["-O0"]                     = "-Od"
    ,   ["-O1"]                     = ""
    ,   ["-Os"]                     = "-O1"
    ,   ["-O3"]                     = "-Ox"
    ,   ["-Ofast"]                  = "-Ox -fp:fast"
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

    -- init features
    _g.features = 
    {
        ["object:sources"]      = false
    }
end

-- get the property
function get(self, name)

    -- get it
    return _g[name]
end

-- make the symbol flag
function nf_symbol(self, level, target)

    -- debug? generate *.pdb file
    local flags = ""
    if level == "debug" then
        if target and target.symbolfile then
            flags = "-ZI -Fd" .. target:symbolfile() 
            if self:has_flags("-ZI -FS -Fd" .. os.tmpfile() .. ".pdb") then
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
function nf_warning(self, level)

    -- the maps
    local maps = 
    {   
        none        = "-W0"
    ,   less        = "-W1"
    ,   more        = "-W3"
    ,   all         = "-W3" -- = "-Wall" will enable too more warnings
    ,   error       = "-WX"
    }

    -- make it
    return maps[level] or ""
end

-- make the optimize flag
function nf_optimize(self, level)

    -- the maps
    local maps = 
    {   
        none        = "-Od"
    ,   fast        = ""
    ,   faster      = "-Ox"
    ,   fastest     = "-Ox -fp:fast"
    ,   smallest    = "-O1"
    ,   aggressive  = "-Ox -fp:fast"
    }

    -- make it
    return maps[level] or ""
end

-- make the vector extension flag
function nf_vectorext(self, extension)

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
function nf_language(self, stdname)

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
    if self:kind() == "cxx" or self:kind() == "mxx" then
        maps = {}
    end

    -- make it
    return maps[stdname] or ""
end

-- make the define flag
function nf_define(self, macro)
    return "-D" .. macro:gsub("\"", "\\\"")
end

-- make the undefine flag
function nf_undefine(self, macro)
    return "-U" .. macro
end

-- make the includedir flag
function nf_includedir(self, dir)
    return "-I" .. dir
end

-- make the complie command
function _compcmd1(self, sourcefile, objectfile, flags)
    return format("%s -c %s -Fo%s %s", self:program(), flags, objectfile, sourcefile)
end

-- complie the source file
function _compile1(self, sourcefile, objectfile, incdepfile, flags)

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
            return os.iorun(_compcmd1(self, sourcefile, objectfile, flags))
        end,
        
        catch
        {
            function (errors)

                -- get prefix: "Note: including file:", @note maybe not english language
                local including_file = errors:match("\n(.-: .-:)%s*.-\r*\n")

                -- filter includes notes
                if errors and including_file then
                    errors = errors:gsub((including_file or "") .. ".-\r*\n", "") 
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
        for includefile in string.gmatch(outdata, ".-: .-:%s*(.-)\r*\n") do

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

-- make the complie command
function compcmd(self, sourcefiles, objectfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    return _compcmd1(self, sourcefiles, objectfile, flags)
end

-- complie the source file
function compile(self, sourcefiles, objectfile, incdepfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    _compile1(self, sourcefiles, objectfile, incdepfile, flags)
end


