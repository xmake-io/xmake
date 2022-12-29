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
-- @file        gcc.lua
--

-- imports
import("core.base.option")
import("core.base.tty")
import("core.base.colors")
import("core.base.global")
import("core.cache.memcache")
import("core.project.config")
import("core.project.policy")
import("core.project.project")
import("core.language.language")
import("utils.progress")
import("private.cache.build_cache")
import("private.service.distcc_build.client", {alias = "distcc_build_client"})

-- init it
function init(self)

    -- init mxflags
    self:set("mxflags", "-pipe"
                      , "-DIBOutlet=__attribute__((iboutlet))"
                      , "-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))"
                      , "-DIBAction=void)__attribute__((ibaction)")

    -- init shflags
    self:set("shflags", "-shared")

    -- add -fPIC for shared
    --
    -- we need check it for clang/gcc with window target
    -- @see https://github.com/xmake-io/xmake/issues/1392
    --
    if not self:is_plat("windows", "mingw") and self:has_flags("-fPIC", "cxflags") then
        self:add("shflags", "-fPIC")
        self:add("shared.cxflags", "-fPIC")
    end

    -- init flags map
    self:set("mapflags", {
        -- warnings
        ["-W1"] = "-Wall"
    ,   ["-W2"] = "-Wall"
    ,   ["-W3"] = "-Wall"
    ,   ["-W4"] = "-Wall -Wextra"
    ,   ["-Weverything"] = "-Wall -Wextra -Weffc++"

         -- strip
    ,   ["-s"]  = "-s"
    ,   ["-S"]  = "-Wl,-S"
    })

    -- for macho target
    if self:is_plat("macosx", "iphoneos") then
        self:add("mapflags", {
            ["-s"] = "-Wl,-x"
        })
    end
end

-- make the strip flag
function nf_strip(self, level, target)
    local maps = {
        debug = "-Wl,-S"
    ,   all   = "-s"
    }
    if self:is_plat("macosx", "iphoneos") then
        maps.all = "-Wl,-x"
    end
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps = _g.symbol_maps
        if not maps then
            maps = {
                debug  = "-g"
            ,   hidden = "-fvisibility=hidden"
            }
            if kind == "cxx" and self:has_flags("-fvisibility-inlines-hidden", "cxflags") then
                maps.hidden_cxx = {"-fvisibility=hidden", "-fvisibility-inlines-hidden"}
            end
            _g.symbol_maps = maps
        end
        return maps[level .. '_' .. kind] or maps[level]
    elseif kind == "ld" or kind == "sh" then
        -- we need add `-g` to linker to generate pdb symbol file for mingw-gcc, llvm-clang on windows
        local plat = self:plat()
        if level == "debug" and (plat == "windows" or (plat == "mingw" and is_host("windows"))) then
            return "-g"
        end
    end
end

-- make the warning flag
function nf_warning(self, level)
    local maps = {
        none       = "-w"
    ,   less       = "-Wall"
    ,   more       = "-Wall"
    ,   all        = "-Wall"
    ,   allextra   = {"-Wall", "-Wextra"}
    ,   everything = self:kind() == "cxx" and {"-Wall", "-Wextra", "-Weffc++"} or {"-Wall", "-Wextra"}
    ,   error      = "-Werror"
    }
    return maps[level]
end

-- make the fp-model flag
function nf_fpmodel(self, level)
    local maps = {
        precise    = "" --default
    ,   fast       = "-ffast-math"
    ,   strict     = {"-frounding-math", "-ftrapping-math"}
    ,   except     = "-ftrapping-math"
    ,   noexcept   = "-fno-trapping-math"
    }
    return maps[level]
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps = {
            none       = "-O0"
        ,   fast       = "-O1"
        ,   faster     = "-O2"
        ,   fastest    = "-O3"
        ,   smallest   = "-Os"
        ,   aggressive = "-Ofast"
        }
        return maps[level]
    end
end

-- make the vector extension flag
function nf_vectorext(self, extension)
    local maps = {
        mmx   = "-mmmx"
    ,   sse   = "-msse"
    ,   sse2  = "-msse2"
    ,   sse3  = "-msse3"
    ,   ssse3 = "-mssse3"
    ,   avx   = "-mavx"
    ,   avx2  = "-mavx2"
    ,   neon  = "-mfpu=neon"
    }
    return maps[extension]
end

-- make the language flag
function nf_language(self, stdname)

    -- the stdc maps
    if _g.cmaps == nil then
        _g.cmaps = {
            -- stdc
            ansi        = "-ansi"
        ,   c89         = "-std=c89"
        ,   gnu89       = "-std=gnu89"
        ,   c99         = "-std=c99"
        ,   gnu99       = "-std=gnu99"
        ,   c11         = "-std=c11"
        ,   gnu11       = "-std=gnu11"
        ,   c17         = "-std=c17"
        ,   gnu17       = "-std=gnu17"
        ,   clatest     = {"-std=c2x", "-std=c17", "-std=c11", "-std=c99", "-std=c89", "-ansi"}
        ,   gnulatest   = {"-std=c2x", "-std=gnu17", "-std=gnu11", "-std=gnu99", "-std=gnu89", "-ansi"}
        }
    end

    -- the stdc++ maps
    if _g.cxxmaps == nil then
        _g.cxxmaps = {
            cxx98        = "-std=c++98"
        ,   gnuxx98      = "-std=gnu++98"
        ,   cxx11        = "-std=c++11"
        ,   gnuxx11      = "-std=gnu++11"
        ,   cxx14        = "-std=c++14"
        ,   gnuxx14      = "-std=gnu++14"
        ,   cxx17        = "-std=c++17"
        ,   gnuxx17      = "-std=gnu++17"
        ,   cxx1z        = "-std=c++1z"
        ,   gnuxx1z      = "-std=gnu++1z"
        ,   cxx20        = {"-std=c++20", "-std=c++2a"}
        ,   gnuxx20      = {"-std=gnu++20", "-std=c++2a"}
        ,   cxx2a        = "-std=c++2a"
        ,   gnuxx2a      = "-std=gnu++2a"
        ,   cxx23        = {"-std=c++23", "-std=c++2b"}
        ,   gnuxx23      = {"-std=gnu++23", "-std=c++2b"}
        ,   cxx2b        = "-std=c++2b"
        ,   gnuxx2b      = "-std=gnu++2b"
        ,   cxxlatest    = {"-std=c++23", "-std=c++2b", "-std=c++20", "-std=c++2a", "-std=c++17", "-std=c++14", "-std=c++11", "-std=c++1z", "-std=c++98"}
        ,   gnuxxlatest  = {"-std=gnu++23", "-std=gnu++2b", "-std=gnu++20", "-std=gnu++2a", "-std=gnu++17", "-std=gnu++14", "-std=gnu++11", "-std=c++1z", "-std=gnu++98"}
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
    elseif self:kind() == "sc" then
        maps = {}
    end
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
    return {"-isystem", path.translate(dir)}
end

-- make the link flag
function nf_link(self, lib)
    return "-l" .. lib
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return {"-L" .. path.translate(dir)}
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    dir = path.translate(dir)
    if self:has_flags("-Wl,-rpath=" .. dir, "ldflags") then
        local flags = {"-Wl,-rpath=" .. (dir:gsub("@[%w_]+", function (name)
            local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
            return maps[name]
        end))}
        if self:is_plat("bsd") then
            -- FreeBSD ld must have "-zorigin" with "-rpath".  Otherwise, $ORIGIN is not translated and it is literal.
            table.insert(flags, 1, "-Wl,-zorigin")
        end
        return flags
    elseif self:has_flags("-Xlinker -rpath -Xlinker " .. dir, "ldflags") then
        return {"-Xlinker", "-rpath", "-Xlinker", (dir:gsub("%$ORIGIN", "@loader_path"))}
    end
end

-- make the framework flag
function nf_framework(self, framework)
    return {"-framework", framework}
end

-- make the frameworkdir flag
function nf_frameworkdir(self, frameworkdir)
    return {"-F" .. path.translate(frameworkdir)}
end

-- make the exception flag
--
-- e.g.
-- set_exceptions("cxx")
-- set_exceptions("objc")
-- set_exceptions("no-cxx")
-- set_exceptions("no-objc")
-- set_exceptions("cxx", "objc")
function nf_exception(self, exp)
    return exp:startswith("no-") and "-fno-exceptions" or "-fexceptions"
end

-- make the c precompiled header flag
function nf_pcheader(self, pcheaderfile, target)
    if self:kind() == "cc" or self:kind() == "mm" then
        local pcoutputfile = target:pcoutputfile("c")
        if self:name() == "clang" then
            return {"-include", pcheaderfile, "-include-pch", pcoutputfile}
        else
            return {"-include", path.filename(pcheaderfile), "-I", path.directory(pcoutputfile)}
        end
    end
end

-- make the c++ precompiled header flag
function nf_pcxxheader(self, pcheaderfile, target)
    if self:kind() == "cxx" or self:kind() == "mxx" then
        local pcoutputfile = target:pcoutputfile("cxx")
        if self:name() == "clang" then
            return {"-include", pcheaderfile, "-include-pch", pcoutputfile}
        else
            return {"-include", path.filename(pcheaderfile), "-I", path.directory(pcoutputfile)}
        end
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
        local maps = {cc = "-x c", cxx = "-x c++"}
        return maps[sourcekind]
    end
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags, opt)

    -- add rpath for dylib (macho), e.g. -install_name @rpath/file.dylib
    local flags_extra = {}
    if targetkind == "shared" and self:is_plat("macosx", "iphoneos", "watchos") then
        table.insert(flags_extra, "-install_name")
        table.insert(flags_extra, "@rpath/" .. path.filename(targetfile))
    end

    -- add `-Wl,--out-implib,outputdir/libxxx.a` for xxx.dll on mingw/gcc
    if targetkind == "shared" and self:is_plat("mingw") then
        table.insert(flags_extra, "-Wl,--out-implib," .. path.join(path.directory(targetfile), path.basename(targetfile) .. ".dll.a"))
    end

    -- init arguments
    opt = opt or {}
    local argv = table.join("-o", targetfile, objectfiles, flags, flags_extra)
    if is_host("windows") and not opt.rawargs then
        argv = winos.cmdargv(argv, {escape = true})
    end
    return self:program(), argv
end

-- link the target file
--
-- maybe we need use os.vrunv() to show link output when enable verbose information
-- @see https://github.com/xmake-io/xmake/discussions/2916
--
function link(self, objectfiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    local program, argv = linkargv(self, objectfiles, targetkind, targetfile, flags)
    if option.get("verbose") then
        os.execv(program, argv, {envs = self:runenvs()})
    else
        os.runv(program, argv, {envs = self:runenvs()})
    end
end

-- has color diagnostics?
function _has_color_diagnostics(self)
    local colors_diagnostics = _g._HAS_COLOR_DIAGNOSTICS
    if colors_diagnostics == nil then
        if io.isatty() and (tty.has_color8() or tty.has_color256()) then
            local theme = colors.theme()
            if theme and theme:name() ~= "plain" then
                -- for gcc
                if self:has_flags("-fdiagnostics-color=always", "cxflags") then
                    colors_diagnostics = "-fdiagnostics-color=always"
                -- for clang
                elseif self:has_flags("-fcolor-diagnostics", "cxflags") then
                    colors_diagnostics = "-fcolor-diagnostics"
                end
            end
        end
        colors_diagnostics = colors_diagnostics or false
        _g._HAS_COLOR_DIAGNOSTICS = colors_diagnostics
    end
    return colors_diagnostics
end

-- get preprocess file path
function _get_cppfile(sourcefile, objectfile)
    return path.join(path.directory(objectfile), "__cpp_" .. path.basename(objectfile) .. path.extension(sourcefile))
end

-- do preprocess
function _preprocess(program, argv, opt)

    -- is gcc or clang?
    local tool = opt.tool
    local is_gcc = false
    local is_clang = false
    if tool then
        if tool:name() == "gcc" or tool:name() == "gxx" then
            is_gcc = true
        elseif tool:name():startswith("clang") then
            is_clang = true
        end
    end

    -- enable "-fdirectives-only"? we need enable it manually
    --
    -- @see https://github.com/xmake-io/xmake/issues/2603
    -- https://github.com/xmake-io/xmake/issues/2425
    local directives_only
    if is_gcc then
        local cachekey = "core.tools." .. tool:name()
        directives_only = memcache.get(cachekey, "directives_only")
        if directives_only == nil then
            if os.isfile(os.projectfile()) and project.policy("preprocessor.gcc.directives_only") then
                directives_only = true
            end
            memcache.set(cachekey, "directives_only", directives_only)
        end
    end

    -- get flags and source file
    local flags = {}
    local cppflags = {}
    local skipped = program:endswith("cache") and 1 or 0
    for _, flag in ipairs(argv) do
        if flag == "-o" then
            break
        end

        -- get preprocessor flags
        table.insert(cppflags, flag)

        -- for c++ modules, we cannot support it for clang now
        if is_clang and flag:startswith("-fmodules") then
            return
        end

        -- we cannot enable "-fdirectives-only"
        if directives_only and (flag:startswith("-D__TIME__=") or
                flag:startswith("-D__DATE__=") or flag:startswith("-D__TIMESTAMP__=")) then
            directives_only = false
        end

        -- get compiler flags
        if flag == "-MMD" or (flag:startswith("-I") and #flag > 2) or flag:startswith("--sysroot=") then
            skipped = 1
        elseif flag == "-MF" or
            flag == "-I" or flag == "-isystem" or flag == "-include" or flag == "-include-pch" or
            flag == "-isysroot" or flag == "-gcc-toolchain" then
            skipped = 2
        elseif flag:endswith("xcrun") then
            skipped = 4
        end
        if skipped > 0 then
            skipped = skipped - 1
        else
            table.insert(flags, flag)
        end
    end
    local objectfile = argv[#argv - 1]
    local sourcefile = argv[#argv]
    assert(objectfile and sourcefile, "%s: iorunv(%s): invalid arguments!", self, program)

    -- is precompiled header?
    if objectfile:endswith(".gch") or objectfile:endswith(".pch") then
        return
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
    table.insert(cppflags, "-E")
    -- it will be faster for preprocessing
    -- when preprocessing, handle directives, but do not expand macros.
    if directives_only then
        table.insert(cppflags, "-fdirectives-only")
    end
    if linemarkers == false then
        table.insert(cppflags, "-P")
    end
    table.insert(cppflags, "-o")
    table.insert(cppflags, cppfile)
    table.insert(cppflags, sourcefile)

    -- we need mark as it when compiling the preprocessed source file
    -- it will indicate to the preprocessor that the input file has already been preprocessed.
    if is_gcc then
        table.insert(flags, "-fpreprocessed")
    end
    -- with -fpreprocessed, predefinition of command line and most builtin macros is disabled.
    if directives_only then
        table.insert(flags, "-fdirectives-only")
    end

    -- do preprocess
    local cppinfo = try {function ()
        local outdata, errdata = os.iorunv(program, cppflags, opt)
        return {outdata = outdata, errdata = errdata,
                sourcefile = sourcefile, objectfile = objectfile, cppfile = cppfile, cppflags = flags}
    end}
    if not cppinfo then
        if is_gcc then
            local cachekey = "core.tools." .. tool:name()
            memcache.set(cachekey, "directives_only", false)
        end
    end
    return cppinfo
end

-- compile preprocessed file
function _compile_preprocessed_file(program, cppinfo, opt)
    local outdata, errdata = os.iorunv(program, table.join(cppinfo.cppflags, "-o", cppinfo.objectfile, cppinfo.cppfile), opt)
    -- we need get warning information from output
    cppinfo.outdata = outdata
    cppinfo.errdata = errdata
end

-- do compile
function _compile(self, sourcefile, objectfile, compflags, opt)
    opt = opt or {}
    local program, argv = compargv(self, sourcefile, objectfile, compflags)
    local function _compile_fallback()
        return os.iorunv(program, argv, {envs = self:runenvs()})
    end
    local cppinfo
    if distcc_build_client.is_distccjob() and distcc_build_client.singleton():has_freejobs() then
        cppinfo = distcc_build_client.singleton():compile(program, argv, {envs = self:runenvs(),
            preprocess = _preprocess, compile = _compile_preprocessed_file, compile_fallback = _compile_fallback,
            tool = self, remote = true})
    elseif build_cache.is_enabled(opt.target) and build_cache.is_supported(self:kind()) then
        cppinfo = build_cache.build(program, argv, {envs = self:runenvs(),
            preprocess = _preprocess, compile = _compile_preprocessed_file, compile_fallback = _compile_fallback,
            tool = self})
    end
    if cppinfo then
        return cppinfo.outdata, cppinfo.errdata
    else
        return _compile_fallback()
    end
end

-- make the compile arguments list for the precompiled header
function _compargv_pch(self, pcheaderfile, pcoutputfile, flags)

    -- remove "-include xxx.h" and "-include-pch xxx.pch"
    local pchflags = {}
    local include = false
    for _, flag in ipairs(flags) do
        if not flag:find("-include", 1, true) then
            if not include then
                table.insert(pchflags, flag)
            end
            include = false
        else
            include = true
        end
    end

    -- compile header.h as c++?
    if self:kind() == "cxx" then
        table.insert(pchflags, "-x")
        table.insert(pchflags, "c++-header")
    end

    -- make the compile arguments list
    return self:program(), table.join("-c", pchflags, "-o", pcoutputfile, pcheaderfile)
end

-- get modules cache directory
function _modules_cachedir(target)
    if target and target.autogendir and target:data("cxx.has_modules") then -- we need ignore option instance
        return path.join(target:autogendir(), "rules", "modules", "cache")
    end
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    -- precompiled header?
    local extension = path.extension(sourcefile)
    if (extension:startswith(".h") or extension == ".inl") then
        return _compargv_pch(self, sourcefile, objectfile, flags)
    end
    return self:program(), table.join("-c", flags, "-o", objectfile, sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags, opt)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    opt = opt or {}
    local depfile = dependinfo and os.tmpfile() or nil
    try
    {
        function ()

            -- support `-MMD -MF depfile.d`? some old gcc does not support it at same time
            if depfile and _g._HAS_MMD_MF == nil then
                _g._HAS_MMD_MF = self:has_flags({"-MMD", "-MF", os.nuldev()}, "cxflags", { flagskey = "-MMD -MF" }) or false
            end

            -- generate includes file
            local compflags = flags
            if depfile and _g._HAS_MMD_MF then
                compflags = table.join(compflags, "-MMD", "-MF", depfile)
            end

            -- has color diagnostics? enable it
            local colors_diagnostics = _has_color_diagnostics(self)
            if colors_diagnostics then
                compflags = table.join(compflags, colors_diagnostics)
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

                -- parse and strip errors
                local lines = errors and tostring(errors):split('\n', {plain = true}) or {}
                if not option.get("verbose") then

                    -- find the start line of error
                    local start = 0
                    for index, line in ipairs(lines) do
                        if line:find("error:", 1, true) or line:find("错误：", 1, true) then
                            start = index
                            break
                        end
                    end

                    -- get 16 lines of errors
                    if start > 0 then
                        lines = table.slice(lines, start, start + ((#lines - start > 16) and 16 or (#lines - start)))
                    end
                end

                -- raise compiling errors
                local results = #lines > 0 and table.concat(lines, "\n") or ""
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
                if ok and errdata and #errdata > 0 and policy.build_warnings() then
                    local lines = errdata:split('\n', {plain = true})
                    if #lines > 0 then
                        if not option.get("diagnosis") then
                            lines = table.slice(lines, 1, (#lines > 16 and 16 or #lines))
                        end
                        local warnings = table.concat(lines, "\n")
                        if progress.showing_without_scroll() then
                            print("")
                        end
                        cprint("${color.warning}%s", warnings)
                    end
                end

                -- generate the dependent includes
                if depfile and os.isfile(depfile) then
                    if dependinfo then
                        dependinfo.depfiles_gcc = io.readfile(depfile, {continuation = "\\"})
                        dependinfo.modules_cachedir = _modules_cachedir(opt.target)
                    end

                    -- remove the temporary dependent file
                    os.tryrm(depfile)
                end
            end
        }
    }
end
