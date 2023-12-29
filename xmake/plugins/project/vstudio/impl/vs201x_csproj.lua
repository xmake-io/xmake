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
-- @author      Kethers
-- @file        vs201x_csproj.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.rule")
import("core.project.config")
import("core.project.project")
import("core.language.language")
import("core.tool.toolchain")
import("private.utils.batchcmds")
import("vsfile")
import("vsutils")
import("plugins.project.vsxmake.getinfo", {rootdir = os.programdir()})


function _make_dirs(dir, csprojdir)
    dir = dir:trim()
    if #dir == 0 then
        return ""
    end
    dir = path.translate(dir)
    if not path.is_absolute(dir) then
        dir = path.relative(path.absolute(dir), csprojdir)
    end
    return dir
end

-- make header
function _make_header(csprojfile, vsinfo)
    csprojfile:print("<?xml version=\"1.0\" encoding=\"utf-8\"?>")
    csprojfile:enter("<Project DefaultTargets=\"Build\" ToolsVersion=\"%s.0\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">", assert(vsinfo.project_version))
end

function _make_configurations(csprojfile, vsinfo, target)
    -- the target name
    local targetname = target.name

    -- init configuration type
    local output_types =
    {
        binary = "Exe"
    -- ,   winexe = "WinExe" TODO: this kind doesn't exist yet
    ,   shared = "Library"
    }

    -- import Microsoft.Common.props
    csprojfile:print("<Import Project=\"%$(MSBuildExtensionsPath)\\%$(MSBuildToolsVersion)\\Microsoft.Common.props\" Condition=\"Exists(\'%$(MSBuildExtensionsPath)\\%$(MSBuildToolsVersion)\\Microsoft.Common.props\')\" />")

    -- make Globals
    csprojfile:enter("<PropertyGroup>")
        csprojfile:print("<Configuration Condition=\" \'%$(Configuration)\' == \'\' \">debug</Configuration>")
        csprojfile:print("<Platform Condition=\" \'%$(Platform)\' == \'\' \">x64</Platform>")
        csprojfile:print("<ProjectGuid>{%s}</ProjectGuid>", hash.uuid4(targetname))
        csprojfile:print("<OutputType>%s</OutputType>", output_types[target.kind] or "Unknown")
        csprojfile:print("<AppDesignerFolder>Properties</AppDesignerFolder>")
        csprojfile:print("<RootNamespace>%s</RootNamespace>", targetname)
        csprojfile:print("<AssemblyName>%s</AssemblyName>", targetname)
        csprojfile:print("<TargetFrameworkVersion>v%s</TargetFrameworkVersion>", vsinfo.dotnetframework_version)
        csprojfile:print("<FileAlignment>512</FileAlignment>")
        csprojfile:print("<AutoGenerateBindingRedirects>true</AutoGenerateBindingRedirects>")
    csprojfile:leave("</PropertyGroup>")

    -- make Configuration
    for _, targetinfo in ipairs(target.info) do
        local mode = targetinfo.mode
        local arch = targetinfo.arch

        symbols  = targetinfo.symbols or ""
        optimize = targetinfo.optimize or ""

        debugtype        = "portable"
        debugsymbols     = "true"
        if (symbols == "debug") then
            debugtype 	 = "full"
            debugsymbols = "true"
        elseif (symbols == "hidden") then
            debugtype    = "none"
            debugsymbols = "false"
        elseif (string.find(symbols, "debug") and string.find(symbols, "embed")) then
            debugtype    = "embedded"
            debugsymbols = "true"
        end

        if optimize == "" or optimize == "none" then
            optimize = "false"
        else
            optimize = "true"
        end

        csprojfile:enter("<PropertyGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\" >", mode, arch)
            csprojfile:print("<DebugType>%s</DebugType>", debugtype)
            csprojfile:print("<DebugSymbols>%s</DebugSymbols>", debugsymbols)
            csprojfile:print("<Optimize>%s</Optimize>", optimize)
            csprojfile:print("<OutputPath>%s</OutputPath>", _make_dirs(targetinfo.targetdir, target.project_dir))
            csprojfile:print("<BaseIntermediateOutputPath>%s</BaseIntermediateOutputPath>", _make_dirs(targetinfo.objectdir, target.project_dir))
            csprojfile:print("<IntermediateOutputPath>%$(BaseIntermediateOutputPath)</IntermediateOutputPath>")
            csprojfile:print("<DefineConstants>%s</DefineConstants>", targetinfo.defines)
            csprojfile:print("<ErrorReport>prompt</ErrorReport>")
            csprojfile:print("<WarningLevel>4</WarningLevel>")
        csprojfile:leave("</PropertyGroup>")
    end
end

-- make source files
function _make_source_files(csprojfile, vsinfo, target)
    -- make source file infos
    local sourceinfos = {}
    for _, targetinfo in ipairs(target.info) do
        for _, sourcebatch in pairs(targetinfo.sourcebatches) do
            local sourcekind = sourcebatch.sourcekind
            local rulename = sourcebatch.rulename
            if (sourcekind == "cs") then
                local objectfiles = sourcebatch.objectfiles
                for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    local objectfile    = objectfiles[idx]
                    -- local flags         = targetinfo.sourceflags[sourcefile]    -- TODO: cs flags doesn't exist yet
                    sourceinfos[sourcefile] = sourceinfos[sourcefile] or {}
                    table.insert(sourceinfos[sourcefile], {targetinfo = targetinfo, mode = targetinfo.mode, arch = targetinfo.arch, sourcekind = sourcekind, objectfile = objectfile, flags = flags, compargv = targetinfo.compargvs[sourcefile]})
                end
            end
        end
    end

    -- make source files
    csprojfile:enter("<ItemGroup>")
    for sourcefile, sourceinfo in table.orderpairs(sourceinfos) do
        if #sourceinfo == #target.info then
            csprojfile:print("<Compile Include=\"%s\" />", path.relative(path.absolute(sourcefile), target.project_dir))
        end
    end
    csprojfile:leave("</ItemGroup>")
end

-- make project references
function _make_project_references(csprojfile, vsinfo, target)
    csprojfile:enter("<ItemGroup>")

    for deptargetname, deptarget in table.orderpairs(target._deps) do
        proj_extension = deptarget.proj_extension or ""
        csprojfile:enter("<ProjectReference Include=\"..\\%s\\%s.%s\"> ", deptargetname, deptargetname, proj_extension)
            csprojfile:print("<Project>{%s}</Project>", hash.uuid4(deptargetname))
            csprojfile:print("<Name>%s</Name>", deptargetname)
        csprojfile:leave("</ProjectReference>")
    end

    csprojfile:leave("</ItemGroup>")
end

-- make tailer
function _make_tailer(csprojfile, vsinfo, target)
    -- import Microsoft.CSharp.targets
    csprojfile:print("<Import Project=\"%$(MSBuildToolsPath)\\Microsoft.CSharp.targets\" />")

    csprojfile:leave("</Project>")
end

-- make csproj
function make(vsinfo, target)

    -- the target name
    local targetname = target.name

    -- the csproj directory
    local csprojdir = target.project_dir

    -- open csproj file
    local csprojpath = path.join(csprojdir, targetname .. ".csproj")
    local csprojfile = vsfile.open(csprojpath, "w")

    -- init indent character
    vsfile.indentchar('  ')

    -- make headers
    _make_header(csprojfile, vsinfo)

    -- make Configurations
    _make_configurations(csprojfile, vsinfo, target)

    -- make source files
    _make_source_files(csprojfile, vsinfo, target)

    -- make project references
    _make_project_references(csprojfile, vsinfo, target)

    -- make tailer
    _make_tailer(csprojfile, vsinfo, target)

    -- exit solution file
    csprojfile:close()
end