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
-- @file        gcc.lua
--

-- imports
import("core.base.option")
import("core.base.colors")
import("core.project.config")
import("core.project.project")
import("core.language.language")
import("private.tools.ccache")
import("private.utils.progress")

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
    if not is_plat("windows", "mingw") then
        self:add("shflags", "-fPIC")
        self:add("shared.cxflags", "-fPIC")
    end

    -- init flags map
    self:set("mapflags",
    {
        -- warnings
        ["-W1"] = "-Wall"
    ,   ["-W2"] = "-Wall"
    ,   ["-W3"] = "-Wall"
    ,   ["-W4"] = "-Wextra"
    ,   ["-Weverything"] = "-Wall -Wextra -Weffc++"

         -- strip
    ,   ["-s"]  = "-s"
    ,   ["-S"]  = "-Wl,-S"
    })

    -- for macho target
    if is_plat("macosx") or is_plat("iphoneos") then
        self:add("mapflags",
        {
            ["-s"] = "-Wl,-x"
        })
    end
end

-- make the strip flag
function nf_strip(self, level)
    local maps =
    {
        debug = "-Wl,-S"
    ,   all   = "-s"
    }
    if is_plat("macosx") or is_plat("iphoneos") then
        maps.all   = "-Wl,-x"
    end
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps = _g.symbol_maps
        if not maps then
            maps =
            {
                debug  = "-g"
            ,   hidden = "-fvisibility=hidden"
            }
            if kind == "cxx" and self:has_flags("-fvisibility-inlines-hidden", "cxflags") then
                maps.hidden_cxx = {"-fvisibility=hidden", "-fvisibility-inlines-hidden"}
            end
            _g.symbol_maps = maps
        end
        return maps[level .. '_' .. kind] or maps[level]
    end
end

-- make the warning flag
function nf_warning(self, level)
    local maps =
    {
        none       = "-w"
    ,   less       = "-Wall"
    ,   more       = "-Wall"
    ,   all        = "-Wall"
    ,   everything = "-Wall -Wextra -Weffc++"
    ,   error      = "-Werror"
    }
    return maps[level]
end

-- make the fp-model flag
function nf_fpmodel(self, level)
    local maps =
    {
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
    local maps =
    {
        none       = "-O0"
    ,   fast       = "-O1"
    ,   faster     = "-O2"
    ,   fastest    = "-O3"
    ,   smallest   = "-Os"
    ,   aggressive = "-Ofast"
    }
    return maps[level]
end

-- make the vector extension flag
function nf_vectorext(self, extension)
    local maps =
    {
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
        _g.cmaps =
        {
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
        }
    end

    -- the stdc++ maps
    if _g.cxxmaps == nil then
        _g.cxxmaps =
        {
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
        ,   cxx20        = "-std=c++2a"
        ,   gnuxx20      = "-std=gnu++2a"
        ,   cxx2a        = "-std=c++2a"
        ,   gnuxx2a      = "-std=gnu++2a"
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
    return "-I" .. os.args(path.translate(dir))
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
    return "-L" .. os.args(path.translate(dir))
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    dir = path.translate(dir)
    if self:has_flags("-Wl,-rpath=" .. dir, "ldflags") then
        return "-Wl,-rpath=" .. os.args(dir:gsub("@[%w_]+", function (name)
            local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
            return maps[name]
        end))
    elseif self:has_flags("-Xlinker -rpath -Xlinker " .. dir, "ldflags") then
        return "-Xlinker -rpath -Xlinker " .. os.args(dir:gsub("%$ORIGIN", "@loader_path"))
    end
end

-- make the framework flag
function nf_framework(self, framework)
    return "-framework " .. framework
end

-- make the frameworkdir flag
function nf_frameworkdir(self, frameworkdir)
    return "-F " .. os.args(path.translate(frameworkdir))
end

-- make the c precompiled header flag
function nf_pcheader(self, pcheaderfile, target)
    if self:kind() == "cc" then
        local pcoutputfile = target:pcoutputfile("c")
        if self:name() == "clang" then
            return "-include " .. os.args(pcheaderfile) .. " -include-pch " .. os.args(pcoutputfile)
        else
            return "-include " .. path.filename(pcheaderfile) .. " -I" .. os.args(path.directory(pcoutputfile))
        end
    end
end

-- make the c++ precompiled header flag
function nf_pcxxheader(self, pcheaderfile, target)
    if self:kind() == "cxx" then
        local pcoutputfile = target:pcoutputfile("cxx")
        if self:name() == "clang" then
            return "-include " .. os.args(pcheaderfile) .. " -include-pch " .. os.args(pcoutputfile)
        else
            return "-include " .. path.filename(pcheaderfile) .. " -I" .. os.args(path.directory(pcoutputfile))
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
    if targetkind == "shared" and is_plat("macosx", "iphoneos", "watchos") then
        table.insert(flags_extra, "-install_name")
        table.insert(flags_extra, "@rpath/" .. path.filename(targetfile))
    end

    -- add `-Wl,--out-implib,outputdir/libxxx.a` for xxx.dll on mingw/gcc
    if targetkind == "shared" and is_plat("mingw") then
        table.insert(flags_extra, "-Wl,--out-implib," .. path.join(path.directory(targetfile), path.basename(targetfile) .. ".lib"))
    end

    -- init arguments
    opt = opt or {}
    local argv = table.join("-o", targetfile, objectfiles, flags, flags_extra)
    if is_host("windows") and not opt.rawargs then
        argv = winos.cmdargv(argv)
    end
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    local program, argv = linkargv(self, objectfiles, targetkind, targetfile, flags)
    os.runv(program, argv, {envs = self:runenvs()})
end

-- has color diagnostics?
function _has_color_diagnostics(self)
    local colors_diagnostics = _g._HAS_COLOR_DIAGNOSTICS
    if colors_diagnostics == nil then
        if io.isatty() and (colors.color8() or colors.color256()) then
            local theme = colors.theme()
            if theme and theme:name() ~= "plain" then
                -- for clang
                if self:has_flags("-fcolor-diagnostics", "cxflags") then
                    colors_diagnostics = "-fcolor-diagnostics"
                -- for gcc
                elseif self:has_flags("-fdiagnostics-color=always", "cxflags") then
                    colors_diagnostics = "-fdiagnostics-color=always"
                end
            end
        end
        colors_diagnostics = colors_diagnostics or false
        _g._HAS_COLOR_DIAGNOSTICS = colors_diagnostics
    end
    return colors_diagnostics
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

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)

    -- precompiled header?
    local extension = path.extension(sourcefile)
    if (extension:startswith(".h") or extension == ".inl") then
        return _compargv_pch(self, sourcefile, objectfile, flags)
    end
    return ccache.cmdargv(self:program(), table.join("-c", flags, "-o", objectfile, sourcefile))
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    -- @note this path here has been normalized, we can quickly find it by the unique path separator prompt
    os.mkdir(path.directory(objectfile, path.sep()))

    -- compile it
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
            local program, argv = compargv(self, sourcefile, objectfile, compflags)
            return os.iorunv(program, argv, {envs = self:runenvs()})
        end,
        catch
        {
            function (errors)

                -- try removing the old object file for forcing to rebuild this source file
                os.tryrm(objectfile)

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
                        lines = table.slice(lines, start, start + ifelse(#lines - start > 16, 16, #lines - start))
                    end
                end

                -- raise compiling errors
                raise(#lines > 0 and table.concat(lines, "\n") or "")
            end
        },
        finally
        {
            function (ok, outdata, errdata)
                -- show warnings?
                if ok and errdata and #errdata > 0 and (option.get("diagnosis") or option.get("warning")) then
                    local lines = errdata:split('\n', {plain = true})
                    if #lines > 0 then
                        local warnings = table.concat(table.slice(lines, 1, ifelse(#lines > 8, 8, #lines)), "\n")
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
                    end

                    -- remove the temporary dependent file
                    os.tryrm(depfile)
                end
            end
        }
    }
end

