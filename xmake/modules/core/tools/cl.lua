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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        cl.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.base.hashset")
import("core.project.project")
import("core.project.policy")
import("core.language.language")
import("private.tools.vstool")
import("private.tools.cl.parse_include")
import("private.cache.build_cache")
import("private.service.distcc_build.client", {alias = "distcc_build_client"})
import("utils.progress")

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
    ,   ["-Wswitch"]                = "-we4062"
    ,   ["-Wswitch-enum"]           = "-we4061"
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
    })
end

-- make the symbol flags
function nf_symbols(self, levels, target)
    local flags = nil
    local values = hashset.from(levels)
    if values:has("debug") then
        flags = {}
        if values:has("edit") then
            table.insert(flags, "-ZI")
        elseif values:has("embed") then
            table.insert(flags, "-Z7")
        else
            table.insert(flags, "-Zi")
        end

        -- generate *.pdb file
        local symbolfile = nil
        if target and target.symbolfile and not values:has("embed") then
            symbolfile = target:symbolfile()
        end
        if symbolfile then

            -- ensure the object directory
            local symboldir = path.directory(symbolfile)
            if not os.isdir(symboldir) then
                os.mkdir(symboldir)
            end

            -- check and add symbol output file
            --
            -- @note we need use `{}` to wrap it to avoid expand it
            -- https://github.com/xmake-io/xmake/issues/2061#issuecomment-1042590085
            local pdbflags = {"-Fd" .. (target:is_static() and symbolfile or path.join(symboldir, "compile." .. path.filename(symbolfile)))}
            if self:has_flags({"-FS", "-Fd" .. os.nuldev() .. ".pdb"}, "cxflags", { flagskey = "-FS -Fd" }) then
                table.insert(pdbflags, 1, "-FS")
            end
            table.insert(flags, pdbflags)
        end
    end
    return flags
end

-- make the fp-model flag
function nf_fpmodel(self, level)
    local maps =
    {
        precise    = "-fp:precise" -- default
    ,   fast       = "-fp:fast"
    ,   strict     = "-fp:strict"
    ,   except     = "-fp:except"
    ,   noexcept   = "-fp:except-"
    }
    return maps[level]
end

-- make the warning flag
function nf_warning(self, level)
    local maps =
    {
        none       = "-w"
    ,   less       = "-W1"
    ,   more       = "-W3"
    ,   all        = "-W3" -- = "-Wall" will enable too more warnings
    ,   allextra   = "-W4"
    ,   everything = "-Wall"
    ,   error      = "-WX"
    }
    return maps[level]
end

-- make the optimize flag
function nf_optimize(self, level)
    local maps =
    {
        none        = "-Od"
    ,   faster      = "-Ox"
    ,   fastest     = "-O2 -fp:fast"
    ,   smallest    = "-O1 -GL" -- /GL and (/OPT:REF is on by default in linker), we need enable /ltcg
    ,   aggressive  = "-O2 -fp:fast"
    }
    return maps[level]
end

-- make vs runtime flag
function nf_runtime(self, vs_runtime)
    if vs_runtime then
        return "-" .. vs_runtime
    end
end

-- make the vector extension flag
function nf_vectorext(self, extension)
    local maps =
    {
        sse    = "-arch:SSE"
    ,   sse2   = "-arch:SSE2"
    ,   avx    = "-arch:AVX"
    ,   avx2   = "-arch:AVX2"
    }
    local flag = maps[extension]
    if flag and self:has_flags(flag, "cxflags") then
        return flag
    end
end

-- make the language flag
-- clang-cl should also use it, @see https://github.com/xmake-io/xmake/issues/2211#issuecomment-1083322178
function nf_language(self, stdname)

    -- the stdc maps
    if _g.cmaps == nil then
        _g.cmaps =
        {
            -- stdc
            c99       = "-TP" -- compile as c++ files because older msvc only support c89
        ,   gnu99     = "-TP"
        ,   c11       = {"-std:c11", "-TP"}
        ,   gnu11     = {"-std:c11", "-TP"}
        ,   c17       = {"-std:c17", "-TP"}
        ,   gnu17     = {"-std:c17", "-TP"}
        ,   clatest   = {"-std:c17", "-std:c11"}
        ,   gnulatest = {"-std:c17", "-std:c11"}
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
        ,   cxx20       = {"-std:c++20", "-std:c++latest"}
        ,   gnuxx20     = {"-std:c++20", "-std:c++latest"}
        ,   cxx2a       = {"-std:c++20", "-std:c++latest"}
        ,   gnuxx2a     = {"-std:c++20", "-std:c++latest"}
        ,   cxx23       = {"-std:c++23", "-std:c++latest"}
        ,   gnuxx23     = {"-std:c++23", "-std:c++latest"}
        ,   cxx2b       = {"-std:c++23", "-std:c++latest"}
        ,   gnuxx2b     = {"-std:c++23", "-std:c++latest"}
        ,   cxxlatest   = "-std:c++latest"
        ,   gnuxxlatest = "-std:c++latest"
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
    local result = maps[stdname]
    if type(result) == "table" then
        for _, v in ipairs(result) do
            if self:has_flags(v, "cxflags") then
                result = v
                maps[stdname] = result
                return result
            end
        end
    else
        return result
    end
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
    return {"-I" .. path.translate(dir)}
end

-- make the sysincludedir flag
function nf_sysincludedir(self, dir)
    local has_external_includedir = _g._HAS_EXTERNAL_INCLUDEDIR
    if has_external_includedir == nil then
        if self:has_flags({"-external:W0", "-external:I" .. os.args(path.translate(dir))}, "cxflags", {flagskey = "cl_external_includedir"}) then
            has_external_includedir = 2 -- full support
        elseif self:has_flags({"-experimental:external", "-external:W0", "-external:I" .. os.args(path.translate(dir))}, "cxflags", {flagskey = "cl_external_includedir_experimental"}) then
            has_external_includedir = 1 -- experimental support
        end
        has_external_includedir = has_external_includedir or 0
        _g._HAS_EXTERNAL_INCLUDEDIR = has_external_includedir
    end
    if has_external_includedir >= 2 then
        return {"-external:W0", "-external:I" .. path.translate(dir)}
    elseif has_external_includedir >= 1 then
        return {"-experimental:external", "-external:W0", "-external:I" .. path.translate(dir)}
    else
        return nf_includedir(self, dir)
    end
end

-- make the exception flag
--
-- e.g.
-- set_exceptions("cxx")
-- set_exceptions("no-cxx")
function nf_exception(self, exp)
    local maps = {
        cxx = "/EHsc",
        ["no-cxx"] = "/EHsc-"
    }
    return maps[exp]
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
        return {"-Yu" .. path.filename(pcheaderfile), "-FI" .. path.filename(pcheaderfile), "-Fp" .. target:pcoutputfile("c")}
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
        return {"-Yu" .. path.filename(pcheaderfile), "-FI" .. path.filename(pcheaderfile), "-Fp" .. target:pcoutputfile("cxx")}
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
function _compargv_pch(self, pcheaderfile, pcoutputfile, flags)

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

-- has /sourceDependencies xxx.json @see https://github.com/xmake-io/xmake/issues/868?
function _has_source_dependencies(self)
    local has_source_dependencies = _g._HAS_SOURCE_DEPENDENCIES
    if has_source_dependencies == nil then
        local source_dependencies_jsonfile = os.tmpfile() .. ".json"
        if self:has_flags("/sourceDependencies " .. source_dependencies_jsonfile, "cxflags", {flagskey = "cl_sourceDependencies",
                on_check = function (ok, errors)
                    -- even if cl does not support /sourceDependencies, it will not interrupt compilation
                    if ok and not os.isfile(source_dependencies_jsonfile) then
                        ok = false
                    end
                    return ok, errors
                end}) then
            has_source_dependencies = true
        end
        has_source_dependencies = has_source_dependencies or false
        _g._HAS_SOURCE_DEPENDENCIES = has_source_dependencies
    end
    return has_source_dependencies
end

function _is_in_vstudio()
    local is_in_vstudio = _g._IS_IN_VSTUDIO
    if is_in_vstudio == nil then
        is_in_vstudio = os.getenv("XMAKE_IN_VSTUDIO") or false
        _g._IS_IN_VSTUDIO = is_in_vstudio
    end
    return is_in_vstudio
end

-- get preprocess file path
function _get_cppfile(sourcefile, objectfile)
    return path.join(path.directory(objectfile), "__cpp_" .. path.basename(objectfile) .. path.extension(sourcefile))
end

-- do preprocess
function _preprocess(program, argv, opt)

    -- get flags and source file
    local flags = {}
    local cppflags = {}
    local skipped = 0
    local objectfile
    local pdbfile
    local sourcefile = argv[#argv]
    local extension = path.extension(sourcefile)
    for _, flag in ipairs(argv) do
        if flag:startswith("-Fo") or flag:startswith("/Fo") then
            objectfile = flag:sub(4)
            break
        end

        -- get preprocessor flags
        -- TODO fix precompiled header bug for /P + /FI
        local target = opt.target
        if target and (flag:startswith("-FI") or flag:startswith("/FI")) then
            local pcheaderfile = target:get("pcheader") or target:get("pcxxheader")
            if pcheaderfile then
                flag = "-FI" .. path.absolute(pcheaderfile)
            end
        end
        table.insert(cppflags, flag)

        -- get compiler flags
        if flag == "-showIncludes" or flag == "/showIncludes" or
           (flag:startswith("-I") and #flag > 2) or (flag:startswith("/I") and #flag > 2) or
           flag:startswith("-external:") or flag:startswith("/external:") then
            skipped = 1
        -- @note we cannot ignore precompiled flags when compiling pch, @see https://github.com/xmake-io/xmake/issues/2885
        elseif not extension:startswith(".h") and (
           flag:startswith("-Yu") or flag:startswith("/Yu") or
           flag:startswith("-FI") or flag:startswith("/FI") or
           flag:startswith("-Fp") or flag:startswith("/Fp")) then
            skipped = 1
        elseif flag == "-I" or flag == "-sourceDependencies" or flag == "/sourceDependencies" then
            skipped = 2
        elseif opt.remote and flag:startswith("-Fd") or flag:startswith("/Fd") then
            skipped = 1
            pdbfile = flag:sub(4) --TODO handle remote pdb
        end
        if skipped > 0 then
            skipped = skipped - 1
        else
            table.insert(flags, flag)
        end
    end
    assert(objectfile and sourcefile, "%s: iorunv(%s): invalid arguments!", self, program)

    -- is precompiled header?
    if objectfile:endswith(".pch") then
        return false
    end

    -- disable linemarkers?
    local linemarkers = _g.linemarkers
    if linemarkers == nil then
        if os.isfile(os.projectfile()) and project.policy("preprocessor.linemarkers") == false then
            linemarkers = false
        else
            linemarkers = true
        end
        _g.linemarkers = linemarkers
    end

    -- do preprocess
    local cppfile = _get_cppfile(sourcefile, objectfile)
    local cppfiledir = path.directory(cppfile)
    if not os.isdir(cppfiledir) then
        os.mkdir(cppfiledir)
    end
    if linemarkers == false then
        table.insert(cppflags, "-EP")
    else
        -- we cannot use `/P`, @see https://github.com/xmake-io/xmake/issues/2445
        table.insert(cppflags, "-E")
    end
    table.insert(cppflags, sourcefile)
    return try{ function()
        -- https://github.com/xmake-io/xmake/issues/2902#issuecomment-1326934902
        local outfile = cppfile
        local errfile = os.tmpfile() .. ".i.err"
        local inherit_handles_safely = true
        if not winos.inherit_handles_safely() then
            outfile = os.tmpfile() .. ".i.out"
            inherit_handles_safely = false
        end
        os.execv(program, winos.cmdargv(cppflags), table.join(opt, {stdout = outfile, stderr = errfile}))
        local errdata
        if os.isfile(errfile) then
            errdata = io.readfile(errfile)
        end
        os.tryrm(errfile)
        if not inherit_handles_safely then
            os.cp(outfile, cppfile)
            os.tryrm(outfile)
        end
        -- includes information will be output to stderr instead of stdout now
        return {outdata = errdata, errdata = errdata,
                sourcefile = sourcefile, objectfile = objectfile, cppfile = cppfile, cppflags = flags,
                pdbfile = pdbfile}
    end}
end

-- compile preprocessed file
function _compile_preprocessed_file(program, cppinfo, opt)
    local outdata, errdata = vstool.iorunv(program, winos.cmdargv(table.join(cppinfo.cppflags, "-Fo" .. cppinfo.objectfile, cppinfo.cppfile)), opt)
    -- we need get warning information from output
    cppinfo.outdata = outdata
    cppinfo.errdata = errdata
end

-- do compile
function _compile(self, sourcefile, objectfile, compflags, opt)
    opt = opt or {}
    local function _compile_fallback()
        local program, argv = compargv(self, sourcefile, objectfile, compflags, opt)
        return vstool.iorunv(program, argv, {envs = self:runenvs()})
    end
    local cppinfo
    if distcc_build_client.is_distccjob() and distcc_build_client.singleton():has_freejobs() then
        local program, argv = compargv(self, sourcefile, objectfile, compflags, table.join(opt, {rawargs = true}))
        cppinfo = distcc_build_client.singleton():compile(program, argv, {envs = self:runenvs(),
            preprocess = _preprocess, compile = _compile_preprocessed_file, compile_fallback = _compile_fallback,
            target = opt.target, tool = self, remote = true})
    elseif build_cache.is_enabled(opt.target) and build_cache.is_supported(self:kind()) then
        local program, argv = compargv(self, sourcefile, objectfile, compflags, table.join(opt, {rawargs = true}))
        cppinfo = build_cache.build(program, argv, {envs = self:runenvs(),
            preprocess = _preprocess, compile = _compile_preprocessed_file, compile_fallback = _compile_fallback,
            target = opt.target, tool = self})
    end
    if cppinfo then
        return cppinfo.outdata, cppinfo.errdata
    else
        return _compile_fallback()
    end
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags, opt)

    -- precompiled header?
    local extension = path.extension(sourcefile)
    if (extension:startswith(".h") or extension == ".inl") then
        return _compargv_pch(self, sourcefile, objectfile, flags)
    end

    -- make the compile arguments list
    local argv = table.join("-c", flags, "-Fo" .. objectfile, sourcefile)
    return self:program(), (opt and opt.rawargs) and argv or winos.cmdargv(argv)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags, opt)

    -- ensure the object directory
    local objectdir = path.directory(objectfile)
    if not os.isdir(objectdir) then
        os.mkdir(objectdir)
    end

    -- compile it
    local depfile = nil
    local outdata = try
    {
        function ()

            -- generate includes file
            local compflags = flags
            if dependinfo then
                if _has_source_dependencies(self) then
                    depfile = os.tmpfile() .. ".json"
                    compflags = table.join(flags, "/sourceDependencies", depfile)
                else
                    compflags = table.join(flags, "-showIncludes")
                end
            end

            -- we need show full file path to goto error position if xmake is called in vstudio
            -- https://github.com/xmake-io/xmake/issues/1049
            if _is_in_vstudio() then
                if compflags == flags then
                    compflags = table.join(flags, "-FC")
                else
                    table.join2(compflags, "-FC")
                end
            end

            -- do compile
            return _compile(self, sourcefile, objectfile, compflags, opt)
        end,
        catch
        {
            function (errors)

                -- try removing the old object file for forcing to rebuild this source file
                os.tryrm(objectfile)

                -- remove preprocess file
                local cppfile = _get_cppfile(sourcefile, objectfile)
                os.tryrm(cppfile)

                -- use cl/stdout as errors first from vstool.iorunv()
                if type(errors) == "table" then
                    local errs = errors.stdout or ""
                    errs = errs .. (errors.stderr or "")
                    errors = errs
                end

                local results = ""
                if depfile then
                    results = tostring(errors)
                else
                    -- filter includes notes: "Note: including file: xxx.h", @note maybe not english language
                    for _, line in ipairs(tostring(errors):split("\n", {plain = true})) do
                        line = line:rtrim()
                        if not parse_include(line) then
                            results = results .. line .. "\r\n"
                        end
                    end
                end
                if not option.get("verbose") then
                    results = results .. "\n  ${yellow}> in ${bright}" .. sourcefile
                end
                raise(results)
            end
        },
        finally
        {
            function (ok, outdata, errdata)

                -- show warnings?
                if ok and policy.build_warnings() then
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
                            if not option.get("diagnosis") then
                                lines = table.slice(lines, 1, (#lines > 16 and 16 or #lines))
                            end
                            local warnings = table.concat(lines, "\r\n")
                            if progress.showing_without_scroll() then
                                print("")
                            end
                            cprint("${color.warning}%s", warnings)
                        end
                    end
                end
            end
        }
    }

    -- generate the dependent includes
    if dependinfo then
        if depfile and os.isfile(depfile) then
            dependinfo.depfiles_cl_json = io.readfile(depfile)
            os.tryrm(depfile)
        elseif outdata then
            dependinfo.depfiles_cl = outdata
        end
    end
end
