--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        vs201x_vcxproj.lua
--

-- imports
import("core.tool.linker")
import("core.tool.compiler")
import("core.project.config")
import("vsfile")

-- make compiling flags
function _make_compflags(sourcefile, target, vcxprojdir)

    -- make the compiling flags
    local _, compflags = compiler.compflags(sourcefile, target)

    -- replace -Idir or /Idir, -Fdsymbol.pdb or /Fdsymbol.pdb
    local flags = {}
    for _, flag in ipairs(compflags) do

        -- replace -Idir or /Idir
        flag = flag:gsub("[%-|/]I(.*)", function (dir)
                        dir = dir:trim()
                        if not path.is_absolute(dir) then
                            dir = path.relative(path.absolute(dir), vcxprojdir)
                        end
                        return "/I" .. dir
                    end)

        -- replace -Fdsymbol.pdb or /Fdsymbol.pdb
        flag = flag:gsub("[%-|/]Fd(.*)", function (dir)
                        dir = dir:trim()
                        if not path.is_absolute(dir) then
                            dir = path.relative(path.absolute(dir), vcxprojdir)
                        end
                        return "/Fd" .. dir
                    end)

        -- save flag
        table.insert(flags, flag)
    end

    -- concat flags
    flags = table.concat(flags, " "):trim()

    -- ok?
    return flags
end

-- make linking flags
function _make_linkflags(target, vcxprojdir)

    -- make the linking flags
    local _, linkflags = linker.linkflags(target)

    -- replace -libpath:dir or /libpath:dir, -pdb:symbol.pdb or /pdb:symbol.pdb
    local flags = {}
    for _, flag in ipairs(linkflags) do

        -- replace -libpath:dir or /libpath:dir
        flag = flag:gsub("[%-|/]libpath:(.*)", function (dir)
                        dir = dir:trim()
                        if not path.is_absolute(dir) then
                            dir = path.relative(path.absolute(dir), vcxprojdir)
                        end
                        return "/libpath:" .. dir
                    end)

        -- replace -pdb:symbol.pdb or /pdb:symbol.pdb
        flag = flag:gsub("[%-|/]pdb:(.*)", function (dir)
                        dir = dir:trim()
                        if not path.is_absolute(dir) then
                            dir = path.relative(path.absolute(dir), vcxprojdir)
                        end
                        return "/pdb:" .. dir
                    end)

        -- save flag
        table.insert(flags, flag)
    end
    
    -- concat flags
    flags = table.concat(flags, " "):trim()

    -- ok?
    return flags
end

-- make header
function _make_header(vcxprojfile, vsinfo, target)

    -- the versions
    local versions = 
    {
        vs2010 = '4'
    ,   vs2012 = '4'
    ,   vs2013 = '12'
    ,   vs2015 = '14'
    ,   vs2017 = '15'
    }

    -- make header
    vcxprojfile:print("<?xml version=\"1.0\" encoding=\"utf-8\"?>")
    vcxprojfile:enter("<Project DefaultTargets=\"Build\" ToolsVersion=\"%s.0\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">", assert(versions["vs" .. vsinfo.vstudio_version]))
end

-- make tailer
function _make_tailer(vcxprojfile, vsinfo, target)
    vcxprojfile:print("<Import Project=\"%$(VCTargetsPath)\\Microsoft.Cpp.targets\" />")
    vcxprojfile:enter("<ImportGroup Label=\"ExtensionTargets\">")
    vcxprojfile:leave("</ImportGroup>")
    vcxprojfile:leave("</Project>")
end

-- make Configurations
function _make_configurations(vcxprojfile, vsinfo, target, vcxprojdir)

    -- the target name
    local targetname = target:name()

    -- init configuration type
    local configuration_types =
    {
        binary = "Application"
    ,   shared = "DynamicLibrary"
    ,   static = "StaticLibrary"
    }

    -- the versions
    local versions = 
    {
        vs2010 = '10'
    ,   vs2012 = '11'
    ,   vs2013 = '12'
    ,   vs2015 = '14'
    ,   vs2017 = '15'
    }

    -- make ProjectConfigurations
    vcxprojfile:enter("<ItemGroup Label=\"ProjectConfigurations\">")
        vcxprojfile:enter("<ProjectConfiguration Include=\"$(mode)|Win32\">")
            vcxprojfile:print("<Configuration>$(mode)</Configuration>")
            vcxprojfile:print("<Platform>Win32</Platform>")
        vcxprojfile:leave("</ProjectConfiguration>")
    vcxprojfile:leave("</ItemGroup>")

    -- make Globals
    vcxprojfile:enter("<PropertyGroup Label=\"Globals\">")
        vcxprojfile:print("<ProjectGuid>{%s}</ProjectGuid>", os.uuid(targetname))
        vcxprojfile:print("<RootNamespace>%s</RootNamespace>", targetname)
    vcxprojfile:leave("</PropertyGroup>")

    -- import Microsoft.Cpp.Default.props
    vcxprojfile:print("<Import Project=\"%$(VCTargetsPath)\\Microsoft.Cpp.Default.props\" />")

    -- make Configuration
    vcxprojfile:enter("<PropertyGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'$(mode)|Win32\'\" Label=\"Configuration\">")
        vcxprojfile:print("<ConfigurationType>%s</ConfigurationType>", assert(configuration_types[target:get("kind")]))
        vcxprojfile:print("<PlatformToolset>v%s0</PlatformToolset>", assert(versions["vs" .. vsinfo.vstudio_version]))
        vcxprojfile:print("<CharacterSet>MultiByte</CharacterSet>")
    vcxprojfile:leave("</PropertyGroup>")

    -- import Microsoft.Cpp.props
    vcxprojfile:print("<Import Project=\"%$(VCTargetsPath)\\Microsoft.Cpp.props\" />")

    -- make ExtensionSettings
    vcxprojfile:enter("<ImportGroup Label=\"ExtensionSettings\">")
    vcxprojfile:leave("</ImportGroup>")

    -- make PropertySheets
    vcxprojfile:enter("<ImportGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'$(mode)|Win32\'\" Label=\"PropertySheets\">")
        vcxprojfile:print("<Import Project=\"%$(UserRootDir)\\Microsoft.Cpp.%$(Platform).user.props\" Condition=\"exists(\'%$(UserRootDir)\\Microsoft.Cpp.%$(Platform).user.props\')\" Label=\"LocalAppDataPlatform\" />")
    vcxprojfile:leave("</ImportGroup>")

    -- make UserMacros
    vcxprojfile:print("<PropertyGroup Label=\"UserMacros\" />")

    -- make OutputDirectory and IntermediateDirectory
    vcxprojfile:enter("<PropertyGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'$(mode)|Win32\'\">")
        vcxprojfile:print("<OutDir>%s\\</OutDir>", path.relative(path.absolute(config.get("buildir")), vcxprojdir))
        vcxprojfile:print("<IntDir>%$(Configuration)\\</IntDir>")
        if target:get("kind") == "binary" then
            vcxprojfile:print("<LinkIncremental>true</LinkIncremental>")
        end
    vcxprojfile:leave("</PropertyGroup>")
end

-- make ItemDefinitionGroup
function _make_item_define_group(vcxprojfile, vsinfo, target, vcxprojdir)

    -- enter ItemDefinitionGroup 
    vcxprojfile:enter("<ItemDefinitionGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'$(mode)|Win32\'\">")
    
    -- for linker?
    if target:get("kind") == "binary" then
        vcxprojfile:enter("<Link>")

            -- make AdditionalOptions
            vcxprojfile:print("<AdditionalOptions>%s %%(AdditionalOptions)</AdditionalOptions>", _make_linkflags(target, vcxprojdir))

            -- generate debug infomation?
            local debug = false
            for _, symbol in ipairs(target:get("symbols")) do
                if symbol == "debug" then
                    debug = true
                    break
                end
            end
            vcxprojfile:print("<GenerateDebugInformation>%s</GenerateDebugInformation>", tostring(debug))

            -- make SubSystem
            vcxprojfile:print("<SubSystem>Console</SubSystem>")
        
            -- make TargetMachine
            vcxprojfile:print("<TargetMachine>%s</TargetMachine>", ifelse(config.arch() == "x64", "MachineX64", "MachineX86"))

        vcxprojfile:leave("</Link>")
    end

    -- for compiler?
    vcxprojfile:enter("<ClCompile>")
        vcxprojfile:print("<Optimization>Disabled</Optimization>") -- disable optimization default
        vcxprojfile:print("<ProgramDataBaseFileName></ProgramDataBaseFileName>") -- disable pdb file default
    vcxprojfile:leave("</ClCompile>")

    -- leave ItemDefinitionGroup 
    vcxprojfile:leave("</ItemDefinitionGroup>")
end

-- make file
function _make_file(vcxprojfile, vsinfo, target, sourcefile, objectfile, vcxprojdir)

    -- get the target key
    local key = tostring(target)

    -- make flags cache
    _g.flags = _g.flags or {}

    -- make flags
    local flags = _g.flags[key] or _make_compflags(sourcefile, target, vcxprojdir)
    _g.flags[key] = flags

    -- add file
    vcxprojfile:enter("<ClCompile Include=\"%s\">", path.relative(path.absolute(sourcefile), vcxprojdir))
        vcxprojfile:print("<AdditionalOptions Condition=\"\'%$(Configuration)|%$(Platform)\'==\'$(mode)|Win32\'\">%s %%(AdditionalOptions)</AdditionalOptions>", flags)
        vcxprojfile:print("<ObjectFileName Condition=\"\'%$(Configuration)|%$(Platform)\'==\'$(mode)|Win32\'\">%s</ObjectFileName>", path.relative(path.absolute(objectfile), vcxprojdir))

        -- complie as c++ if exists flag: /TP
        if flags:find("[%-|/]TP") then
            vcxprojfile:print("<CompileAs Condition=\"\'%$(Configuration)|%$(Platform)\'==\'$(mode)|Win32\'\">CompileAsCpp</CompileAs>")
        end

    vcxprojfile:leave("</ClCompile>")
end

function _make_header_file(vcxprojfile, includefile, vcxprojdir)
    vcxprojfile:print("<ClInclude Include=\"%s\" />", path.relative(path.absolute(includefile), vcxprojdir))
end

-- make source code list
function _make_source_code_list(vcxprojfile, vsinfo, target, vcxprojdir)

    -- enter ItemGroup
    vcxprojfile:enter("<ItemGroup>")

        -- add files
        local objectfiles = target:objectfiles()
        for idx, sourcefile in ipairs(target:sourcefiles()) do
            _make_file(vcxprojfile, vsinfo, target, sourcefile, objectfiles[idx], vcxprojdir) 
        end

    vcxprojfile:leave("</ItemGroup>")

    -- enter header group
    vcxprojfile:enter("<ItemGroup>")

        -- add headers
        for _, includefile in ipairs(target:headerfiles()) do
            _make_header_file(vcxprojfile, includefile, vcxprojdir)
        end
    vcxprojfile:leave("</ItemGroup>")
end

-- make vcxproj
function make(vsinfo, target)

    -- the target name
    local targetname = target:name()

    -- the vcxproj directory
    local vcxprojdir = path.join(vsinfo.solution_dir, targetname)

    -- open vcxproj file
    local vcxprojfile = vsfile.open(path.join(vcxprojdir, targetname .. ".vcxproj"), "w")

    -- init indent character
    vsfile.indentchar('  ')

    -- make header
    _make_header(vcxprojfile, vsinfo, target)

    -- make Configurations
    _make_configurations(vcxprojfile, vsinfo, target, vcxprojdir)

    -- make ItemDefinitionGroup
    _make_item_define_group(vcxprojfile, vsinfo, target, vcxprojdir)

    -- make source code list
    _make_source_code_list(vcxprojfile, vsinfo, target, vcxprojdir)

    -- make tailer
    _make_tailer(vcxprojfile, vsinfo, target)

    -- exit solution file
    vcxprojfile:close()
end
