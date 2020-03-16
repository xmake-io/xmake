--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        cl.lua
--

-- imports
import("core.base.option")
import("core.project.project")
import("core.language.language")
import("private.tools.vstool")
import("private.tools.cl.parse_include")

-- init it
function init(self)

    -- init cxflags
    self:set("cxflags", "-nologo")

    -- init flags map
    self:set("mapflags",
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
    ,   ["-Weverything"]            = "-Wall"
    ,   ["-Wextra"]                 = "-W4"
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
    })
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
            flags = "-Zi -Fd" .. path.join(symboldir, "compile." .. path.filename(symbolfile))
            if self:has_flags({"-Zi", "-FS", "-Fd" .. os.nuldev() .. ".pdb"}, "cxflags", { flagskey = "-Zi -FS -Fd" }) then
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
        none       = "-W0"
    ,   less       = "-W1"
    ,   more       = "-W3"
    ,   all        = "-W3" -- = "-Wall" will enable too more warnings
    ,   everything = "-Wall"
    ,   error      = "-WX"
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
    if flag and self:has_flags(flag, "cxflags") then
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
        ,   cxx1z       = "-std:c++17"
        ,   gnuxx1z     = "-std:c++17"
        ,   cxx20       = "-std:c++latest"
        ,   gnuxx20     = "-std:c++latest"
        ,   cxx2a       = "-std:c++latest"
        ,   gnuxx2a     = "-std:c++latest"
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
    if flag and flag:find("std:c++", 1, true) and not self:has_flags(flag, "cxflags") then
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
    return "-I" .. os.args(path.translate(dir))
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

-- add the special flags for the given source file of target
--
-- @note only it called when fileconfig is set
--
function add_sourceflags(self, sourcefile, fileconfig, target, targetkind)

    -- add language type flags explicitly if the sourcekind is changed.
    --
    -- because compiler maybe compile `.c` as c++. 
    -- e.g. 
    --   add_files("*.c", {sourcekind = "cxx"})
    --
    local sourcekind = fileconfig.sourcekind
    if sourcekind and sourcekind ~= language.sourcekind_of(sourcefile) then
        local maps = {cc = "-TC", cxx = "-TP"}
        return maps[sourcekind]
    end
end

-- make the compile arguments list for the precompiled header
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

    -- make the compile arguments list
    return self:program(), table.join("-c", "-Yc", pchflags, "-Fp" .. pcoutputfile, "-Fo" .. pcoutputfile .. ".obj", pcheaderfile)
end

-- make the compile arguments list
function _compargv1(self, sourcefile, objectfile, flags)

    -- precompiled header?
    local extension = path.extension(sourcefile)
    if (extension:startswith(".h") or extension == ".inl") then
        return _compargv1_pch(self, sourcefile, objectfile, flags)
    end

    -- make the compile arguments list
    return self:program(), table.join("-c", flags, "-Fo" .. objectfile, sourcefile)
end

-- compile the source file
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

            -- use vstool to compile and enable vs_unicode_output @see https://github.com/xmake-io/xmake/issues/528
            return vstool.iorunv(_compargv1(self, sourcefile, objectfile, compflags))
        end,
        catch
        {
            function (errors)

                -- use cl/stdout as errors first from vstool.iorunv()
                if type(errors) == "table" then
                    local errs = errors.stdout or ""
                    if #errs:trim() == 0 then
                        errs = errors.stderr or ""
                    end
                    errors = errs
                end

                -- try removing the old object file for forcing to rebuild this source file
                os.tryrm(objectfile)

                -- filter includes notes: "Note: including file: xxx.h", @note maybe not english language
                local results = ""
                for _, line in ipairs(tostring(errors):split("\n", {plain = true})) do
                    line = line:rtrim()
                    if not parse_include(line) then
                        results = results .. line .. "\r\n"
                    end
                end
                os.raise(results)
            end
        },
        finally
        {
            function (ok, outdata, errdata)

                -- show warnings?
                if ok and (option.get("diagnosis") or option.get("warning")) then
                    local output = outdata or ""
                    if #output:trim() == 0 then
                        output = errdata or ""
                    end
                    if #output:trim() > 0 then
                        local lines = {}
                        for _, line in ipairs(output:split("\n", {plain = true})) do
                            line = line:rtrim()
                            if line:match("warning %a+[0-9]+%s*:") then
                                table.insert(lines, line)
                            end
                        end
                        if #lines > 0 then
                            local warnings = table.concat(table.slice(lines, 1, ifelse(#lines > 8, 8, #lines)), "\r\n")
                            cprint("${color.warning}%s", warnings)
                        end
                    end
                end
            end
        }
    }

    -- generate the dependent includes
    if dependinfo and outdata then
        dependinfo.depfiles_cl = outdata
    end
end

-- make the compile arguments list
function compargv(self, sourcefiles, objectfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    return _compargv1(self, sourcefiles, objectfile, flags)
end

-- compile the source file
function compile(self, sourcefiles, objectfile, dependinfo, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    _compile1(self, sourcefiles, objectfile, dependinfo, flags)
end

