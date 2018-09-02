--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
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
    _g.cxflags = { "-nologo" }

    -- init flags map
    _g.mapflags = 
    {
        -- optimize
        ["-O0"]                     = "-Od"
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
        local symbolfile = nil
        if target and target.symbolfile then
            symbolfile = target:symbolfile()
        end
        if symbolfile then

            -- ensure the object directory
            local symboldir = path.directory(symbolfile)
            if not os.isdir(symboldir) then
                os.mkdir(symboldir)
            end
            
            -- check and add symbol output file
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
    ,   faster      = "-O2"
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
    if _g.cmaps == nil then
        _g.cmaps = 
        {
            -- stdc
            c99   = "-TP" -- compile as c++ files because msvc only support c89
        ,   gnu99 = "-TP"
        ,   c11   = "-TP"
        ,   gnu11 = "-TP"
        }
    end

    -- the stdc++ maps
    if _g.cxxmaps == nil then
        _g.cxxmaps = 
        {
            cxx11       = "-std:c++11"
        ,   gnuxx11     = "-std:c++11"
        ,   cxx14       = "-std:c++14"
        ,   gnuxx14     = "-std:c++14"
        ,   cxx17       = "-std:c++17"
        ,   gnuxx17     = "-std:c++17"
        ,   cxx1z       = "-std:c++latest"
        ,   gnuxx1z     = "-std:c++latest"
        }
        local cxxmaps2 = {}
        for k, v in pairs(_g.cxxmaps) do
            cxxmaps2[k:gsub("xx", "++")] = v
        end
        table.join2(_g.cxxmaps, cxxmaps2)
    end

    -- select maps
    local maps = _g.cmaps
    if self:kind() == "cxx" or self:kind() == "mxx" then
        maps = _g.cxxmaps
    end

    -- map it
    local flag = maps[stdname]

    -- not support it?
    if flag and flag:find("std:c++", 1, true) and not self:has_flags(flag) then
        return 
    end

    -- ok
    return flag
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
    return "-I" .. os.args(dir)
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
        return "-Yu" .. path.filename(pcheaderfile) .. " -FI" .. path.filename(pcheaderfile) .. " -Fp" .. os.args(target:pcoutputfile("c"))
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
        return "-Yu" .. path.filename(pcheaderfile) .. " -FI" .. path.filename(pcheaderfile) .. " -Fp" .. os.args(target:pcoutputfile("cxx"))
    end
end

-- contain: "Note: including file: "?
--
-- @note we cannot get better solution to distinguish between `includes` and `error infos`
--
function _include_note(self, line)

    -- init notes
    --
    -- TODO zh-tw, zh-hk, jp, ...
    --
    _g.notes = _g.notes or 
    {
        "Note: including file: "
    ,   "\215\162\210\226: \176\252\186\172\206\196\188\254: " -- zh-cn: "注意: 包含文件: "
    }

    -- contain notes?
    for idx, note in ipairs(_g.notes) do
        
        -- dump line bytes
        --[[
        print(line)
        line:gsub(".", function (ch) print(string.byte(ch)) end)
        --]]

        if line:startswith(note) then
            -- optimization: move this note to head
            if idx ~= 1 then
                table.insert(_g.notes, 1, note)
            end
            return line:sub(#note):trim()
        end
    end
end

-- get include deps
function _include_deps(self, outdata)

    -- translate it
    local results = {}
    local uniques = {}
    for _, line in ipairs(outdata:split("\r\n")) do

        -- get includefile
        local includefile = _include_note(self, line)
        if includefile then

            -- get the relative
            includefile = path.relative(includefile, project.directory())

            -- save it if belong to the project
            if path.absolute(includefile):startswith(os.projectdir()) then

                -- insert it and filter repeat
                if not uniques[includefile] then
                    table.insert(results, includefile)
                    uniques[includefile] = true
                end
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
function _compile1(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    local objectdir = path.directory(objectfile)
    if not os.isdir(objectdir) then
        os.mkdir(objectdir)
    end

    -- compile it
    local outdata = try
    {
        function ()

            -- generate includes file
            local compflags = flags
            if dependinfo then
                compflags = table.join(flags, "-showIncludes")
            end
            return os.iorunv(_compargv1(self, sourcefile, objectfile, compflags))
        end,
        
        catch
        {
            function (errors)

                -- try removing the old object file for forcing to rebuild this source file
                os.tryrm(objectfile)

                -- filter includes notes: "Note: including file: xxx.h", @note maybe not english language
                local results = ""
                for _, line in ipairs(errors:split("\r\n")) do
                    if not _include_note(self, line) then 
                        results = results .. line .. "\r\n"
                    end
                end
                os.raise(results)
            end
        }
    }

    -- generate the dependent includes
    if dependinfo and outdata then
        dependinfo.files = dependinfo.files or {}
        table.join2(dependinfo.files, _include_deps(self, outdata))
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
function compile(self, sourcefiles, objectfile, dependinfo, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    _compile1(self, sourcefiles, objectfile, dependinfo, flags)
end


