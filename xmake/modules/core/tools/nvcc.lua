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
-- @file        nvcc.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("core.language.language")
import("private.tools.ccache")
import("private.utils.progress")

-- init it
function init(self)

    -- init cuflags
    if not is_plat("windows", "mingw") then
        self:set("shared.cuflags", "-Xcompiler -fPIC")
        self:set("binary.cuflags", "-Xcompiler -fPIE")
    end

    -- add -ccbin
    local cu_ccbin = platform.tool("cu-ccbin")
    if cu_ccbin then
        self:add("cuflags", "-ccbin=" .. os.args(cu_ccbin))
    end

    -- init flags map
    self:set("mapflags",
    {
        -- warnings
        ["-W4"]            = "-Wreorder"
    ,   ["-Wextra"]        = "-Wreorder"
    ,   ["-Weverything"]   = "-Wreorder"
    })
end

-- make the symbol flag
function nf_symbol(self, level, target)

    -- debug? generate *.pdb file
    local flags = nil
    if level == "debug" then
        flags = "-g -lineinfo"
        if is_plat("windows") then
            local host_flags = nil
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
                host_flags = "-Zi -Fd" .. path.join(symboldir, "compile." .. path.filename(symbolfile))
                if self:has_flags({'-Xcompiler "-Zi -FS -Fd' .. os.nuldev() .. '.pdb"'}, "cuflags", { flagskey = '-Xcompiler "-Zi -FS -Fd"' }) then
                    host_flags = "-FS " .. host_flags
                end
            else
                host_flags = "-Zi"
            end
            flags = flags .. ' -Xcompiler "' .. host_flags .. '"'
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
        none       = "-w"
    ,   everything = "-Wreorder"
    ,   error      = "-Werror"
    }

    -- for cl.exe on windows
    local cl_maps =
    {
        none       = "-W0"
    ,   less       = "-W1"
    ,   more       = "-W3"
    ,   all        = "-W3" -- = "-Wall" will enable too more warnings
    ,   everything = "-Wall"
    ,   error      = "-WX"
    }

    -- for gcc & clang on linux, may be work for other gnu compatible compilers such as icc
    --
    -- gcc dosen't support `-Weverything`, use `-Wall -Wextra -Weffc++` for it
    -- no warning will emit for unsupoorted `-W` flags by clang/gcc
    --
    local gcc_clang_maps =
    {
        none       = "-w"
    ,   less       = "-Wall"
    ,   more       = "-Wall"
    ,   all        = "-Wall"
    ,   everything = "-Weverything -Wall -Wextra -Weffc++"
    ,   error      = "-Werror"
    }

    -- get warning for nvcc
    local warning = maps[level]

    -- add host warning
    --
    -- for cl.exe on windows, it is the only supported host compiler on the platform
    -- for gcc/clang, or any gnu compatible compiler on *nix
    --
    local host_warning = nil
    if is_plat("windows") then
        host_warning = cl_maps[level]
    else
        host_warning = gcc_clang_maps[level]
    end
    if host_warning then
        warning = ((warning or "") .. ' -Xcompiler "' .. host_warning .. '"'):trim()
    end
    return warning

end

-- make the optimize flag
function nf_optimize(self, level)

    -- the maps
    local maps =
    {
        none       = "-O0"
    ,   fast       = "-O1"
    ,   faster     = "-O2"
    ,   fastest    = "-O3"
    ,   smallest   = "-Os"
    ,   aggressive = "-Ofast"
    }

    -- make it
    return maps[level]
end

-- make the language flag
function nf_language(self, stdname)

    -- the stdc++ maps
    if _g.cxxmaps == nil then
        _g.cxxmaps =
        {
            cxx03       = "--std c++03"
        ,   cxx11       = "--std c++11"
        ,   cxx14       = "--std c++14"
        }
        local cxxmaps2 = {}
        for k, v in pairs(_g.cxxmaps) do
            cxxmaps2[k:gsub("xx", "++")] = v
        end
        table.join2(_g.cxxmaps, cxxmaps2)
    end
    return _g.cxxmaps[stdname]
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
    return "-L" .. os.args(dir)
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    if self:has_flags("-Wl,-rpath=" .. dir, "ldflags") then
        return "-Wl,-rpath=" .. os.args(dir:gsub("@[%w_]+", function (name)
            local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
            return maps[name]
        end))
    elseif self:has_flags("-Xlinker -rpath -Xlinker " .. dir, "ldflags") then
        return "-Xlinker -rpath -Xlinker " .. os.args(dir:gsub("%$ORIGIN", "@loader_path"))
    end
end

-- make the c precompiled header flag
function nf_pcheader(self, pcheaderfile, target)
    return "-include " .. os.args(pcheaderfile)
end

-- make the c++ precompiled header flag
function nf_pcxxheader(self, pcheaderfile, target)
    return "-include " .. os.args(pcheaderfile)
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)

    -- add rpath for dylib (macho), e.g. -install_name @rpath/file.dylib
    local flags_extra = {}
    if targetkind == "shared" and targetfile:endswith(".dylib") then
        table.insert(flags_extra, "-Xlinker")
        table.insert(flags_extra, "-install_name")
        table.insert(flags_extra, "-Xlinker")
        table.insert(flags_extra, "@rpath/" .. path.filename(targetfile))
    end

    -- add `-Wl,--out-implib,outputdir/libxxx.a` for xxx.dll on mingw/gcc
    if targetkind == "shared" and config.plat() == "mingw" then
        table.insert(flags_extra, "-Xlinker")
        table.insert(flags_extra, "-Wl,--out-implib," .. os.args(path.join(path.directory(targetfile), path.basename(targetfile) .. ".lib")))
    end

    -- make link args
    return self:program(), table.join("-o", targetfile, objectfiles, flags, flags_extra)
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- support `-MMD -MF depfile.d`? some old gcc does not support it at same time
function _has_flags_mmd_mf(self)
    local has_mmd_mf = _g._HAS_MMD_MF
    if has_mmd_mf == nil then
       has_mmd_mf = self:has_flags({"-MMD", "-MF", os.nuldev()}, "cuflags", { flagskey = "-MMD -MF" }) or false
        _g._HAS_MMD_MF = has_mmd_mf
    end
    return has_mmd_mf
end

-- support `-MM -o depfile.d`?
function _has_flags_mm(self)
    local has_mm = _g._HAS_MM
    if not has_mmd_mf and has_mm == nil then
        has_mm = self:has_flags("-MM", "cuflags", { flagskey = "-MM" }) or false
        _g._HAS_MM = has_mm
    end
    return has_mm
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return ccache.cmdargv(self:program(), table.join("-c", flags, "-o", objectfile, sourcefile))
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    local depfile = dependinfo and os.tmpfile() or nil
    try
    {
        function ()

            -- generate includes file
            local compflags = flags
            if depfile then
                if _has_flags_mmd_mf(self) then
                    compflags = table.join(compflags, "-MMD", "-MF", depfile)
                elseif _has_flags_mm(self) then
                    -- since -MD is not supported, run nvcc twice
                    os.runv(compargv(self, sourcefile, depfile, table.join(flags, "-MM")))
                end
            end

            -- do compile
            local outdata, errdata = os.iorunv(compargv(self, sourcefile, objectfile, compflags))
            return (outdata or "") .. (errdata or "")
        end,
        catch
        {
            function (errors)

                -- try removing the old object file for forcing to rebuild this source file
                os.tryrm(objectfile)

                -- find the start line of error
                errors = tostring(errors)
                local lines = errors:split("\n", {plain = true})
                local start = 0
                for index, line in ipairs(lines) do
                    if line:find("error:", 1, true) or line:find("错误：", 1, true) then
                        start = index
                        break
                    end
                end

                -- get 16 lines of errors
                if start > 0 or not option.get("verbose") then
                    if start == 0 then start = 1 end
                    errors = table.concat(table.slice(lines, start, start + ifelse(#lines - start > 16, 16, #lines - start)), "\n")
                end

                -- raise compiling errors
                raise(errors)
            end
        },
        finally
        {
            function (ok, warnings)

                -- print some warnings
                if warnings and #warnings > 0 and (option.get("verbose") or option.get("warning")) then
                    if progress.showing_without_scroll() then
                        print("")
                    end
                    cprint("${color.warning}%s", table.concat(table.slice(warnings:split('\n', {plain = true}), 1, 8), '\n'))
                end

                -- generate the dependent includes
                if depfile and os.isfile(depfile) then
                    if dependinfo then
                        -- nvcc uses gcc-style depfiles
                        dependinfo.depfiles_gcc = io.readfile(depfile, {continuation = "\\"})
                    end

                    -- remove the temporary dependent file
                    os.tryrm(depfile)
                end
            end
        }
    }
end

