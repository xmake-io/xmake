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
import("core.language.language")

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

    -- init buildmodes
    _g.buildmodes = 
    {
        ["object:sources"]      = false
    }
end

-- get the property
function get(self, name)
    return _g[name]
end

-- make the symbol flag
function nf_symbol(self, level, target)

    -- debug? generate *.pdb file
    local flags = nil
    if level == "debug" then
        if target and target.symbolfile then
            flags = "-Zi -Fd" .. target:symbolfile()
            if self:has_flags({"-Zi", "-FS", "-Fd" .. os.tmpfile() .. ".pdb"}) then
                flags = "-FS " .. flags
            end
        else
            flags = "-Zi"
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
        none  = "-W0"
    ,   less  = "-W1"
    ,   more  = "-W3"
    ,   all   = "-W3" -- = "-Wall" will enable too more warnings
    ,   error = "-WX"
    }

    -- make it
    return maps[level] 
end

-- make the optimize flag
function nf_optimize(self, level)

    -- the maps
    local maps = 
    {   
        none        = "-Od"
    ,   faster      = "-Ox"
    ,   fastest     = "-Ox -fp:fast"
    ,   smallest    = "-O1"
    ,   aggressive  = "-Ox -fp:fast"
    }

    -- make it
    return maps[level]
end

-- make the vector extension flag
function nf_vectorext(self, extension)

    -- the maps
    local maps =
    {   
        sse    = "-arch:SSE"
    ,   sse2   = "-arch:SSE2"
    ,   avx    = "-arch:AVX"
    ,   avx2   = "-arch:AVX2"
    }

    -- check it
    local flag = maps[extension]
    if flag and self:has_flags(flag) then
        return flag
    end
end

-- make the language flag
function nf_language(self, stdname)

    -- the stdc maps
    local cmaps = 
    {
        -- stdc
        c99   = "-TP" -- compile as c++ files because msvc only support c89
    ,   gnu99 = "-TP"
    ,   c11   = "-TP"
    ,   gnu11 = "-TP"
    }

    -- select maps
    local maps = cmaps
    if self:kind() == "cxx" or self:kind() == "mxx" then
        maps = {}
    end

    -- make it
    return maps[stdname]
end

-- make the define flag
function nf_define(self, macro)
    return "-D" .. macro
end

-- make the undefine flag
function nf_undefine(self, macro)
    return "-U" .. macro
end

-- make the includedir flag
function nf_includedir(self, dir)
    return "-I" .. dir
end

-- make the c precompiled header flag
function nf_pcheader(self, pcheaderfile, target)

    -- for c source file
    if self:kind() == "cc" then

        -- patch objectfile
        local objectfiles = target:objectfiles()
        if objectfiles then
            table.insert(objectfiles, target:pcoutputfile("c") .. ".obj")
        end

        -- make flag
        return "-Yu" .. path.filename(pcheaderfile) .. " -Fp" .. target:pcoutputfile("c")
    end
end

-- make the c++ precompiled header flag
function nf_pcxxheader(self, pcheaderfile, target)

    -- for c++ source file
    if self:kind() == "cxx" then

        -- patch objectfile
        local objectfiles = target:objectfiles()
        if objectfiles then
            table.insert(objectfiles, target:pcoutputfile("cxx") .. ".obj")
        end

        -- make flag
        return "-Yu" .. path.filename(pcheaderfile) .. " -Fp" .. target:pcoutputfile("cxx")
    end
end

-- get include deps
function _include_deps(self, outdata)

    -- translate it
    local results = {}
    local uniques = {}
    for includefile in string.gmatch(outdata, ".-: .-:%s*(.-)\r*\n") do

        -- slower, only for debuging
        -- assert(os.isfile(includefile), "invalid include file: %s for %s", includefile, depinfo)

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
    return results
end

-- make the complie arguments list for the precompiled header
function _compargv1_pch(self, pcheaderfile, pcoutputfile, flags)

    -- remove "-Yuxxx.h" and "-Fpxxx.pch"
    local pchflags = {}
    for _, flag in ipairs(flags) do
        if not flag:find("-Yu", 1, true) and not flag:find("-Fp", 1, true) then
            table.insert(pchflags, flag)
        end
    end

    -- compile as c/c++ source file
    if self:kind() == "cc" then
        table.insert(pchflags, "-TC")
    elseif self:kind() == "cxx" then
        table.insert(pchflags, "-TP")
    end

    -- make complie arguments list
    return self:program(), table.join("-c", "-Yc", pchflags, "-Fp" .. pcoutputfile, "-Fo" .. pcoutputfile .. ".obj", pcheaderfile)
end

-- make the complie arguments list
function _compargv1(self, sourcefile, objectfile, flags)

    -- precompiled header?
    local extension = path.extension(sourcefile)
    if (extension:startswith(".h") or extension == ".inl") then
        return _compargv1_pch(self, sourcefile, objectfile, flags)
    end

    -- make complie arguments list
    return self:program(), table.join("-c", flags, "-Fo" .. objectfile, sourcefile)
end

-- complie the source file
function _compile1(self, sourcefile, objectfile, depinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    local outdata = try
    {
        function ()

            -- generate includes file
            local compflags = flags
            if depinfo then
                compflags = table.join(flags, "-showIncludes")
            end
            return os.iorunv(_compargv1(self, sourcefile, objectfile, compflags))
        end,
        
        catch
        {
            function (errors)

                -- try removing the old object file for forcing to rebuild this source file
                os.tryrm(objectfile)

                -- get prefix: "Note: including file:", @note maybe not english language
                local including_file = errors:match("\n(.-: .-:)%s*.-\r*\n")

                -- filter includes notes
                if errors and #errors:split("\n") > 10 and including_file then
                    errors = errors:gsub((including_file or "") .. ".-\r*\n", "") 
                end
                os.raise(errors)
            end
        }
    }

    -- generate the dependent includes
    if depinfo and outdata then
        depinfo.includes = _include_deps(self, outdata)
    end
end

-- make the complie arguments list
function compargv(self, sourcefiles, objectfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    return _compargv1(self, sourcefiles, objectfile, flags)
end

-- complie the source file
function compile(self, sourcefiles, objectfile, depinfo, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    _compile1(self, sourcefiles, objectfile, depinfo, flags)
end


