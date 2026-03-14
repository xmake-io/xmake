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
-- @file        dotnet.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- init it
function init(self)
end

-- make the define flag
function nf_define(self, macro)
    return {"-p:DefineConstants=" .. macro}
end

-- make the optimize flag
function nf_optimize(self, level)
    local maps = {
        none       = "-p:Optimize=false"
    ,   fast       = "-p:Optimize=true"
    ,   faster     = "-p:Optimize=true"
    ,   fastest    = "-p:Optimize=true"
    ,   smallest   = "-p:Optimize=true"
    ,   aggressive = "-p:Optimize=true"
    }
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)
    local maps = {
        debug = {"-p:DebugType=full", "-p:DebugSymbols=true"}
    }
    return maps[level]
end

-- make the warning flag
function nf_warning(self, level)
    local maps = {
        none       = "-p:WarningLevel=0"
    ,   less       = "-p:WarningLevel=1"
    ,   more       = "-p:WarningLevel=3"
    ,   all        = "-p:WarningLevel=5"
    ,   allextra   = "-p:WarningLevel=9999"
    ,   error      = {"-p:WarningLevel=5", "-p:TreatWarningsAsErrors=true"}
    }
    return maps[level]
end

-- get the .csproj file from source files
function _get_csprojfile(sourcefiles, opt)
    local target = opt and opt.target
    if target then
        local csprojfile = target:data("csharp.csproj")
        if csprojfile then
            return csprojfile
        end
    end
    -- find .csproj from source files
    for _, sourcefile in ipairs(sourcefiles) do
        if sourcefile:endswith(".csproj") then
            return sourcefile
        end
    end
end

-- get dotnet verbosity level
function _get_verbosity()
    if option.get("diagnosis") then
        return "diagnostic"
    end
    return "quiet"
end

-- get build configuration from mode
function _get_configuration()
    local mode = config.mode() or "release"
    if mode:lower() == "debug" then
        return "Debug"
    end
    return "Release"
end

-- make the build arguments list
function buildargv(self, sourcefiles, targetkind, targetfile, flags, opt)
    local argv = {"build"}

    -- add .csproj file
    local csprojfile = _get_csprojfile(sourcefiles, opt)
    if csprojfile then
        table.insert(argv, csprojfile)
    end

    -- add common options
    table.join2(argv, {"--nologo", "--configuration", _get_configuration(), "--verbosity", _get_verbosity()})

    -- add output directory
    table.join2(argv, {"--output", path.directory(targetfile)})

    -- add flags
    if flags then
        table.join2(argv, flags)
    end
    return self:program(), argv
end

-- build the target file
function build(self, sourcefiles, targetkind, targetfile, flags, opt)
    os.mkdir(path.directory(targetfile))
    local program, argv = buildargv(self, sourcefiles, targetkind, targetfile, flags, opt)
    os.runv(program, argv, {envs = self:runenvs()})
end
