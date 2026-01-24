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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        fpc.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- init it
function init(self)
    if not self:is_plat("windows", "mingw") then
        self:add("shared.pcflags", "-Cg")
    end
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps =
        {
            none       = "-O-"
        ,   fast       = "-O1"
        ,   fastest    = "-O3"
        ,   smallest   = "-O2"
        ,   aggressive = "-O4"
        }
        return maps[level]
    end
end

-- make the strip flag
function nf_strip(self, level)
    if level == "all" then
        return "-Xs"
    end
end

-- make the symbol flag
function nf_symbol(self, level)
    if level == "debug" and self:kind() == "pc" then
        if self:is_plat("windows") then
            return {"-gw3", "-WN"}
        else
            return "-gw3"
        end
    end
end

-- make the link flag
function nf_link(self, lib)
    return "-k-l" .. lib
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return {"-k-L" .. dir}
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    dir = path.translate(dir)
    if self:has_flags("-k-rpath=" .. dir, "ldflags") then
        return {"-k-rpath=" .. (dir:gsub("@[%w_]+", function (name)
            local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
            return maps[name]
        end))}
    end
end

-- make the framework flag
function nf_framework(self, framework)
    return {"-k-framework", framework}
end

-- make the frameworkdir flag
function nf_frameworkdir(self, frameworkdir)
    return {"-k-F", path.translate(frameworkdir)}
end

-- make the includedir flag
function nf_includedir(self, includedir)
    return {"-Fi" .. path.translate(includedir)}
end

-- make the unitdir flag
function nf_unitdir(self, unitdir)
    return {"-Fu" .. path.translate(unitdir)}
end

-- make the define flag
function nf_define(self, macro)
    return {"-d" .. macro}
end

-- make the undefine flag
function nf_undefine(self, macro)
    return {"-u" .. macro}
end

-- make the language flag
function nf_language(self, language)
    local mode = {
        pascal = "-Mfpc",
        fpc = "-Mfpc",
        objfpc = "-Mobjfpc",
        delphi = "-Mdelphi",
        macpas = "-Mmacpas",
        isopas = "-Miso",
        extendedpascal = "-Mextendedpascal",
        delphiunicode = "-Mdelphiunicode",
    }
    return mode[language:lower()]
end

-- make the exception flag
-- considering this applies to all dialects,
-- make this only accept on/off
function nf_exception(self, exp)
    return {exp == "none" and "-Sx-" or "-Sx"}
end

-- make the compile arguments list
function buildargv(self, sourcefile, targetfile, flags, opt)
    opt = opt or {}
    local argv = table.join(flags)

    -- -FE sets the output path for exes AND unit outputs (.o and .ppu).
    -- (note that .o still get procuded for executables)
    -- -FU sets the output path for unit outputs only, overriding -FE.
    local objectdir = opt.target and opt.target:objectdir()
    if objectdir then
        table.insert(argv, "-FU" .. objectdir)
    end

    -- Practically -FE is the same as -o for executables (except that one
    -- needs a folder path, one needs a file path)
    if opt.target and opt.target:kind() == "binary" then
        table.insert(argv, "-o" .. targetfile)
    end

    table.insert(argv, sourcefile)

    return self:program(), argv
end

-- compile the target file
-- @note: -s flag can be used to skip assembling+linking files.
function build(self, sourcefile, targetfile, dependinfo, flags, opt)
    opt = opt or {}
    os.runv(buildargv(self, sourcefile, targetfile, flags, opt))
end
