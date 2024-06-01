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
-- @file        upgrade_vsproj.lua
--

-- imports
import("core.base.option")
import("core.tool.toolchain")
import("plugins.project.vstudio.impl.vsinfo", {rootdir = os.programdir()})
import("private.utils.toolchain", {alias = "toolchain_utils"})

-- the options
local options = {
    {nil, "vs",              "kv", nil, "Set the vs version. (default: latest)."     }
,   {nil, "vs_toolset",      "kv", nil, "Set the vs toolset."                        }
,   {nil, "vs_sdkver",       "kv", nil, "Set the vs sdk version."                    }
,   {nil, "vs_projectfiles", "vs", nil, "Set the solution or project files."         }
}

-- upgrade *.sln
function _upgrade_sln(projectfile, opt)
    opt = opt or {}
    local msvc = opt.msvc or import("core.tool.toolchain").load("msvc")
    local vs_version = opt.vs or msvc:config("vs")
    local vs_info = assert(vsinfo(tonumber(vs_version)), "unknown vs version!")
    io.gsub(projectfile, "Microsoft Visual Studio Solution File, Format Version %d+%.%d+",
        "Microsoft Visual Studio Solution File, Format Version " .. vs_info.solution_version .. ".00")
    io.gsub(projectfile, "# Visual Studio %d+", "# Visual Studio " .. vs_version)
end

-- upgrade *.vcxproj
function _upgrade_vcxproj(projectfile, opt)
    opt = opt or {}
    local msvc = opt.msvc or import("core.tool.toolchain").load("msvc")
    local vs_version = opt.vs or msvc:config("vs")
    local vs_info = assert(vsinfo(tonumber(vs_version)), "unknown vs version!")
    local vs_sdkver = opt.vs_sdkver or msvc:config("vs_sdkver") or vs_info.sdk_version
    local vs_toolset = toolchain_utils.get_vs_toolset_ver(opt.vs_toolset or msvc:config("vs_toolset")) or vs_info.toolset_version
    local vs_toolsver = vs_info.project_version
    io.gsub(projectfile, "<PlatformToolset>v%d+</PlatformToolset>",
        "<PlatformToolset>" .. vs_toolset .. "</PlatformToolset>")
    io.gsub(projectfile, "<WindowsTargetPlatformVersion>.*</WindowsTargetPlatformVersion>",
        "<WindowsTargetPlatformVersion>" .. vs_sdkver .. "</WindowsTargetPlatformVersion>")
    if vs_toolsver then
        io.gsub(projectfile, "ToolsVersion=\".-\"", "ToolsVersion=\"" .. vs_toolsver .. "\"")
    end
end

-- upgrade vs project file
function upgrade(projectfile, opt)
    if projectfile:endswith(".sln") then
        _upgrade_sln(projectfile, opt)
    elseif projectfile:endswith(".vcxproj") or projectfile:endswith(".props") then
        _upgrade_vcxproj(projectfile, opt)
    end
end

-- https://github.com/xmake-io/xmake/issues/3871
function main(...)
    local argv = {...}
    local opt  = option.parse(argv, options, "Upgrade all the vs project files."
                                           , ""
                                           , "Usage: xmake l private.utils.upgrade_vsproj [options]")

    for _, projectfile in ipairs(opt.vs_projectfiles) do
        upgrade(projectfile, opt)
    end
end
