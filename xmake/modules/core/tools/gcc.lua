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

function init(self)

    -- init mxflags
    self:set("mxflags", "-pipe"
                      , "-DIBOutlet=__attribute__((iboutlet))"
                      , "-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))"
                      , "-DIBAction=void)__attribute__((ibaction)")

    -- init shflags
    self:set("shflags", "-shared")

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

-- we can only call has_flags in load(),
-- as it requires the full platform toolchain flags.
--
function load(self)
    -- add -fPIC for shared
    --
    -- we need check it for clang/gcc with window target
    -- @see https://github.com/xmake-io/xmake/issues/1392
    --
    if not self:is_plat("windows", "mingw") and self:has_flags("-fPIC") then
        self:add("shflags", "-fPIC")
        self:add("shared.cxflags", "-fPIC")
    end
end

-- make the strip flag
function nf_strip(self, level)
    local maps = {
        debug = "-Wl,-S"
    ,   all   = "-s"
    }
    if self:is_plat("macosx", "iphoneos", "watchos", "appletvos", "applexros") then
        maps.all = {"-Wl,-x", "-Wl,-dead_strip"}
    elseif self:is_plat("windows") then
        -- clang does not it on windows, TODO maybe we need test it for gcc
        maps = {}
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
        -- we need to add `-g` to linker to generate pdb symbol file for mingw-gcc, llvm-clang on windows
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
    ,   extra      = "-Wextra"
    ,   pedantic   = "-Wpedantic"
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
-- @see https://github.com/xmake-io/xmake/issues/1613
function nf_vectorext(self, extension)
    local maps = {
        mmx        = "-mmmx"
    ,   sse        = "-msse"
    ,   sse2       = "-msse2"
    ,   sse3       = "-msse3"
    ,   ssse3      = "-mssse3"
    ,   ["sse4.2"] = "-msse4.2"
    ,   avx        = "-mavx"
    ,   avx2       = "-mavx2"
    ,   avx512     = {"-mavx512f", "-mavx512dq", "-mavx512bw", "-mavx512vl"}
    ,   fma        = "-mfma"
    ,   neon       = "-mfpu=neon"
    ,   all        = "-march=native"
    }
    if extension == "all" and self:is_cross() then
        -- https://github.com/xmake-io/xmake-repo/pull/4040#discussion_r1605121207
        maps[extension] = nil
    end
    return maps[extension]
end

-- has -static-libstdc++?
function _has_static_libstdcxx(self)
    local has_static_libstdcxx = _g._HAS_STATIC_LIBSTDCXX
    if has_static_libstdcxx == nil then
        if self:has_flags("-static-libstdc++ -Werror", "ldflags", {flagskey = "gcc_static_libstdcxx"}) then
            has_static_libstdcxx = true
        end
        has_static_libstdcxx = has_static_libstdcxx or false
        _g._HAS_STATIC_LIBSTDCXX = has_static_libstdcxx
    end
    return has_static_libstdcxx
end

-- make the runtime flag
function nf_runtime(self, runtime, opt)
    opt = opt or {}
    local maps
    local kind = self:kind()
    if not self:is_plat("android") then -- we will set runtimes in android ndk toolchain
        maps = maps or {}
        if kind == "ld" or kind == "sh" then
            local target = opt.target
            if target and target.sourcekinds and table.contains(table.wrap(target:sourcekinds()), "cxx") then
                if runtime:endswith("_static") and _has_static_libstdcxx(self) then
                    maps["stdc++_static"] = "-static-libstdc++"
                end
            end
        end
    end
    return maps and maps[runtime]
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
        ,   c90         = "-std=c90"
        ,   gnu90       = "-std=gnu90"
        ,   c99         = "-std=c99"
        ,   gnu99       = "-std=gnu99"
        ,   c11         = "-std=c11"
        ,   gnu11       = "-std=gnu11"
        ,   c17         = "-std=c17"
        ,   gnu17       = "-std=gnu17"
        ,   c23         = {"-std=c23", "-std=c2x"}
        ,   gnu23       = {"-std=gnu23", "-std=gnu2x"}
        ,   clatest     = {"-std=c23", "-std=c2x", "-std=c17", "-std=c11", "-std=c99", "-std=c89", "-ansi"}
        ,   gnulatest   = {"-std=gnu23", "-std=gnu2x", "-std=gnu17", "-std=gnu11", "-std=gnu99", "-std=gnu89", "-ansi"}
        }
    end

    -- the stdc++ maps
    if _g.cxxmaps == nil then
        _g.cxxmaps = {
            cxx98        = "-std=c++98"
        ,   gnuxx98      = "-std=gnu++98"
        ,   cxx03        = "-std=c++03"
        ,   gnuxx03      = "-std=gnu++03"
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
        ,   cxx2c        = "-std=c++2c"
        ,   gnuxx2c      = "-std=gnu++2c"
        ,   cxx26        = {"-std=c++26", "-std=c++2c"}
        ,   gnuxx26      = {"-std=gnu++26", "-std=gnu++2c"}
        ,   cxxlatest    = {"-std=c++26", "-std=c++2c", "-std=c++23", "-std=c++2b", "-std=c++20", "-std=c++2a", "-std=c++17", "-std=c++14", "-std=c++11", "-std=c++1z", "-std=c++98"}
        ,   gnuxxlatest  = {"-std=gnu++26", "-std=gnu++2c", "-std=gnu++23", "-std=gnu++2", "-std=gnu++20", "-std=gnu++2a", "-std=gnu++17", "-std=gnu++14", "-std=gnu++11", "-std=c++1z", "-std=gnu++98"}
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
    return {"-D" .. macro}
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

-- make the force include flag
function nf_forceinclude(self, headerfile, opt)
    local target = opt.target
    local sourcekinds = target and target:extraconf("forceincludes", headerfile, "sourcekinds")
    if not sourcekinds or table.contains(table.wrap(sourcekinds), self:kind()) then
        return {"-include", headerfile}
    end
end

-- make the link flag
function nf_link(self, lib)
    if self:is_plat("linux") and (lib:endswith(".a") or lib:endswith(".so")) and not lib:find(path.sep(), 1, true) then
        return "-l:" .. lib
    elseif lib:endswith(".a") or lib:endswith(".so") or lib:endswith(".dylib") or lib:endswith(".lib") then
        return lib
    else
        return "-l" .. lib
    end
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the link group flag
function nf_linkgroup(self, linkgroup, opt)
    local linkflags = {}
    for _, lib in ipairs(linkgroup) do
        table.insert(linkflags, nf_link(self, lib))
    end
    local flags = {}
    local extra = opt.extra
    if extra and not self:is_plat("macosx", "windows", "mingw") then
        local as_needed = extra.as_needed
        local whole = extra.whole
        local group = extra.group
        local static = extra.static
        local prefix_flags = {}
        local suffix_flags = {}
        if static then
            table.insert(prefix_flags, "-Wl,-Bstatic")
            table.insert(suffix_flags, 1, "-Wl,-Bdynamic")
        end
        -- https://github.com/xmake-io/xmake/issues/5621
        if as_needed then
            table.insert(prefix_flags, "-Wl,--as-needed")
            table.insert(suffix_flags, 1, "-Wl,--no-as-needed")
        elseif as_needed == false then
            table.insert(prefix_flags, "-Wl,--no-as-needed")
            table.insert(suffix_flags, 1, "-Wl,--as-needed")
        end
        if whole then
            table.insert(prefix_flags, "-Wl,--whole-archive")
            table.insert(suffix_flags, 1, "-Wl,--no-whole-archive")
        end
        if group then
            table.insert(prefix_flags, "-Wl,--start-group")
            table.insert(suffix_flags, 1, "-Wl,--end-group")
        end
        table.join2(flags, prefix_flags, linkflags, suffix_flags)
    end
    if #flags == 0 then
        flags = linkflags
    end
    return flags
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return {"-L" .. path.translate(dir)}
end

-- make the rpathdir flag
function nf_rpathdir(self, dir, opt)
    if self:is_plat("windows", "mingw") then
        return
    end
    opt = opt or {}
    local extra = opt.extra
    if extra and extra.installonly then
        return
    end
    dir = path.translate(dir)
    if self:has_flags("-Wl,-rpath=" .. dir, "ldflags") then
        local flags = {"-Wl,-rpath=" .. (dir:gsub("@[%w_]+", function (name)
            local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
            return maps[name]
        end))}
        -- add_rpathdirs("...", {runpath = false})
        -- https://github.com/xmake-io/xmake/issues/5109
        if extra then
            if extra.runpath == false and self:has_flags("-Wl,-rpath=" .. dir .. ",--disable-new-dtags", "ldflags") then
                flags[1] = flags[1] .. ",--disable-new-dtags"
            elseif extra.runpath == true and self:has_flags("-Wl,-rpath=" .. dir .. ",--enable-new-dtags", "ldflags") then
                flags[1] = flags[1] .. ",--enable-new-dtags"
            end
        end
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

-- make the encoding flag
-- @see https://github.com/xmake-io/xmake/issues/2471
--
-- e.g.
-- set_encodings("utf-8")
-- set_encodings("source:utf-8", "target:utf-8")
function nf_encoding(self, encoding)
    local kind
    local charset
    local splitinfo = encoding:split(":")
    if #splitinfo > 1 then
        kind = splitinfo[1]
        charset = splitinfo[2]
    else
        charset = encoding
    end
    local charsets = {
        ["utf-8"] = "UTF-8",
        utf8 = "UTF-8"
    }
    local flags = {}
    charset = charsets[charset:lower()]
    if charset then
        if kind == "source" or not kind then
            table.insert(flags, "-finput-charset=" .. charset)
        end
        if kind == "target" or not kind then
            table.insert(flags, "-fexec-charset=" .. charset)
        end
    end
    if #flags > 0 then
        return flags
    end
end

-- make the c precompiled header flag
function nf_pcheader(self, pcheaderfile, opt)
    if self:kind() == "cc" then
        local target = opt.target
        local pcoutputfile = target:pcoutputfile("c")
        if self:name() == "clang" then
            return {"-include", pcheaderfile, "-include-pch", pcoutputfile}
        else
            return {"-I", path.directory(pcoutputfile), "-include", path.filename(pcheaderfile)}
        end
    end
end

-- make the c++ precompiled header flag
function nf_pcxxheader(self, pcheaderfile, opt)
    if self:kind() == "cxx" then
        local target = opt.target
        local pcoutputfile = target:pcoutputfile("cxx")
        if self:name() == "clang" then
            return {"-include", pcheaderfile, "-include-pch", pcoutputfile}
        else
            return {"-I", path.directory(pcoutputfile), "-include", path.filename(pcheaderfile)}
        end
    end
end

-- make the objc precompiled header flag
function nf_pmheader(self, pcheaderfile, opt)
    if self:kind() == "mm" then
        local target = opt.target
        local pcoutputfile = target:pcoutputfile("m")
        if self:name() == "clang" then
            return {"-include", pcheaderfile, "-include-pch", pcoutputfile}
        else
            return {"-I", path.directory(pcoutputfile), "-include", path.filename(pcheaderfile)}
        end
    end
end

-- make the objc++ precompiled header flag
function nf_pmxxheader(self, pcheaderfile, opt)
    if self:kind() == "mxx" then
        local target = opt.target
        local pcoutputfile = target:pcoutputfile("mxx")
        if self:name() == "clang" then
            return {"-include", pcheaderfile, "-include-pch", pcoutputfile}
        else
            return {"-I", path.directory(pcoutputfile), "-include", path.filename(pcheaderfile)}
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
        if not table.contains(flags, "-install_name") then
            table.insert(flags_extra, "-install_name")
            table.insert(flags_extra, "@rpath/" .. path.filename(targetfile))
        end
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
-- maybe we need to use os.vrunv() to show link output when enable verbose information
-- @see https://github.com/xmake-io/xmake/discussions/2916
--
function link(self, objectfiles, targetkind, targetfile, flags, opt)
    opt = opt or {}
    os.mkdir(path.directory(targetfile))
    local program, argv = linkargv(self, objectfiles, targetkind, targetfile, flags)
    if option.get("verbose") then
        os.execv(program, argv, {envs = self:runenvs(), shell = opt.shell})
    else
        os.vrunv(program, argv, {envs = self:runenvs(), shell = opt.shell})
    end
end

-- get `-MMD -MF depfile.d` flags, some old gcc does not support it at same time
function _get_depfile_flags(self)
    local depfile_flags = _g._DEPFILE_FLAGS
    if depfile_flags == nil then
        local nuldev = os.nuldev()
        if self:name():startswith("cosmoc") then
            nuldev = os.tmpfile()
        end
        if self:has_flags({"-MMD", "-MF", nuldev}, "cxflags", { flagskey = "-MMD -MF" }) then
            depfile_flags = {"-MMD", "-MF"}
        end
        _g._DEPFILE_FLAGS = depfile_flags or false
    end
    return depfile_flags
end

-- get color diagnostics flag
function _get_color_diagnostics_flag(self)
    local colors_diagnostics = _g._COLOR_DIAGNOSTICS
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

                -- enable color output for windows, @see https://github.com/xmake-io/xmake-vscode/discussions/260
                if colors_diagnostics and self:name() == "clang" and is_host("windows") and
                    self:has_flags("-fansi-escape-codes", "cxflags") then
                    colors_diagnostics = table.join(colors_diagnostics, "-fansi-escape-codes")
                end
            end
        end
        colors_diagnostics = colors_diagnostics or false
        _g._COLOR_DIAGNOSTICS = colors_diagnostics
    end
    return colors_diagnostics
end

-- has gnu-line-marker flag?
function _has_gnu_line_marker_flag(self)
    local gnu_line_marker = _g._HAS_GNU_LINE_MARKER
    if gnu_line_marker == nil then
        if self:has_flags({"-Wno-gnu-line-marker", "-Werror"}, "cxflags") then
            gnu_line_marker = true
        end
        gnu_line_marker = gnu_line_marker or false
        _g._HAS_GNU_LINE_MARKER = gnu_line_marker
    end
    return gnu_line_marker
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
        elseif tool:name() == "circle" then
            return
        end
    end

    -- enable "-fdirectives-only"? we need to enable it manually
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
    -- if we want to support pch for gcc, we need to enable this flag
    -- and clang need not this flag, it will use '-include-pch' to include and preprocess header files
    -- but it will be slower than non-ccache mode.
    --
    -- @see https://github.com/xmake-io/xmake/issues/5858
    -- https://musescore.org/en/node/182331
    if is_gcc then
        table.insert(cppflags, "-fpch-preprocess")
    end
    table.insert(cppflags, "-o")
    table.insert(cppflags, cppfile)
    table.insert(cppflags, sourcefile)

    -- we need to mark as it when compiling the preprocessed source file
    -- it will indicate to the preprocessor that the input file has already been preprocessed.
    if is_gcc then
        table.insert(flags, "-fpreprocessed")
    end
    -- with -fpreprocessed, predefinition of command line and most builtin macros is disabled.
    if directives_only then
        table.insert(flags, "-fdirectives-only")
    end

    -- suppress -Wgnu-line-marker warnings
    -- @see https://github.com/xmake-io/xmake/issues/5737
    if (is_gcc or is_clang) and _has_gnu_line_marker_flag(tool) then
        table.insert(flags, "-Wno-gnu-line-marker")
    end

    -- do preprocess
    local cppinfo = try {function ()
        if is_host("windows") then
            cppflags = winos.cmdargv(cppflags, {escape = true})
        end
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
    local argv = table.join(cppinfo.cppflags, "-o", cppinfo.objectfile, cppinfo.cppfile)
    if is_host("windows") then
        argv = winos.cmdargv(argv, {escape = true})
    end
    local outdata, errdata = os.iorunv(program, argv, opt)
    -- we need to get warning information from output
    -- and we need to reserve warnings output from preprocessing
    -- @see https://github.com/xmake-io/xmake/issues/5858
    if outdata then
        cppinfo.outdata = (cppinfo.outdata or "") .. outdata
    end
    if errdata then
        cppinfo.errdata = (cppinfo.errdata or "") .. errdata
    end
end

-- do compile
function _compile(self, sourcefile, objectfile, compflags, opt)
    opt = opt or {}
    local program, argv = compargv(self, sourcefile, objectfile, compflags, opt)
    local function _compile_fallback()
        local runargv = argv
        if is_host("windows") then
            runargv = winos.cmdargv(argv, {escape = true})
        end
        return os.iorunv(program, runargv, {envs = self:runenvs(), shell = opt.shell})
    end
    local cppinfo
    if distcc_build_client.is_distccjob() and distcc_build_client.singleton():has_freejobs() then
        cppinfo = distcc_build_client.singleton():compile(program, argv, {envs = self:runenvs(),
            preprocess = _preprocess, compile = _compile_preprocessed_file, compile_fallback = _compile_fallback,
            tool = self, remote = true, shell = opt.shell})
    elseif build_cache.is_enabled(opt.target) and build_cache.is_supported(self:kind()) then
        cppinfo = build_cache.build(program, argv, {envs = self:runenvs(),
            preprocess = _preprocess, compile = _compile_preprocessed_file, compile_fallback = _compile_fallback,
            tool = self, shell = opt.shell})
    end
    if cppinfo then
        return cppinfo.outdata, cppinfo.errdata
    else
        return _compile_fallback()
    end
end

-- make the compile arguments list for the precompiled header
function _compargv_pch(self, pcheaderfile, pcoutputfile, flags, opt)

    -- remove "-include xxx.h" and "-include-pch xxx.pch"
    local pchflags = {}
    local include = false
    for _, flag in ipairs(flags) do
        if not flag:startswith("-include") then
            if not include then
                table.insert(pchflags, flag)
            end
            include = false
        else
            include = true
        end
    end

    -- set the language of precompiled header?
    if self:kind() == "cxx" then
        table.insert(pchflags, "-x")
        table.insert(pchflags, "c++-header")
    elseif self:kind() == "cc" then
        table.insert(pchflags, "-x")
        table.insert(pchflags, "c-header")
    elseif self:kind() == "mxx" then
        table.insert(pchflags, "-x")
        table.insert(pchflags, "objective-c++-header")
    elseif self:kind() == "mm" then
        table.insert(pchflags, "-x")
        table.insert(pchflags, "objective-c-header")
    end

    -- make the compile arguments list
    local argv = table.join("-c", pchflags, "-o", pcoutputfile, pcheaderfile)
    return self:program(), argv
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags, opt)

    -- precompiled header?
    local extension = path.extension(sourcefile)
    if (extension:startswith(".h") or extension == ".inl") then
        return _compargv_pch(self, sourcefile, objectfile, flags, opt)
    end

    local argv = table.join("-c", flags, "-o", objectfile, sourcefile)
    return self:program(), argv
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags, opt)
    opt = opt or {}
    os.mkdir(path.directory(objectfile))

    local depfile = dependinfo and os.tmpfile() or nil
    try
    {
        function ()

            -- generate includes file
            local compflags = flags
            if depfile then
                local depfile_flags = _get_depfile_flags(self)
                if depfile_flags then
                    compflags = table.join(compflags, depfile_flags, depfile)
                end
            end

            -- attempt to enable color diagnostics
            local colors_diagnostics = _get_color_diagnostics_flag(self)
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
                if ok and errdata and #errdata > 0 and policy.build_warnings(opt) then
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
                        dependinfo.depfiles_format = "gcc"
                        dependinfo.depfiles = io.readfile(depfile, {continuation = "\\"})
                    end

                    -- remove the temporary dependent file
                    os.tryrm(depfile)
                end
            end
        }
    }
end
