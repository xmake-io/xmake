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
function _make_compflags(sourcefile, targetinfo, vcxprojdir)

    -- make the compiling flags
    local _, compflags = compiler.compflags(sourcefile, targetinfo.target)

    -- switch to the given mode and arch
    config.set("mode", targetinfo.mode)
    config.set("arch", ifelse(targetinfo.arch == "Win32", "x86", "x64"))

    -- translate path for -Idir or /Idir, -Fdsymbol.pdb or /Fdsymbol.pdb
    local flags = {}
    for _, flag in ipairs(compflags) do

        -- -Idir or /Idir
        flag = flag:gsub("[%-|/]I(.*)", function (dir)
                        dir = dir:trim()
                        if not path.is_absolute(dir) then
                            dir = path.relative(path.absolute(dir), vcxprojdir)
                        end
                        return "/I" .. dir
                    end)

        -- -Fdsymbol.pdb or /Fdsymbol.pdb
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

    -- ok?
    return flags
end

-- make linking flags
function _make_linkflags(targetinfo, vcxprojdir)

    -- switch to the given mode and arch
    config.set("mode", targetinfo.mode)
    config.set("arch", ifelse(targetinfo.arch == "Win32", "x86", "x64"))

    -- make the linking flags
    local _, linkflags = linker.linkflags(targetinfo.target)

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
    
    -- ok?
    return flags
end

-- make header
function _make_header(vcxprojfile, vsinfo)

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
function _make_tailer(vcxprojfile, vsinfo)
    vcxprojfile:print("<Import Project=\"%$(VCTargetsPath)\\Microsoft.Cpp.targets\" />")
    vcxprojfile:enter("<ImportGroup Label=\"ExtensionTargets\">")
    vcxprojfile:leave("</ImportGroup>")
    vcxprojfile:leave("</Project>")
end

-- make Configurations
function _make_configurations(vcxprojfile, vsinfo, target, vcxprojdir)

    -- the target name
    local targetname = target.name

    -- init configuration type
    local configuration_types =
    {
        binary = "Application"
    ,   shared = "DynamicLibrary"
    ,   static = "StaticLibrary"
    }

    -- the toolset versions
    local toolset_versions = 
    {
        vs2010 = "100"
    ,   vs2012 = "110"
    ,   vs2013 = "120"
    ,   vs2015 = "140"
    ,   vs2017 = "141"
    }

    -- the sdk version
    local sdk_versions = 
    {
        vs2015 = "10.0.10240.0"
    ,   vs2017 = "10.0.14393.0"
    }

    -- make ProjectConfigurations
    vcxprojfile:enter("<ItemGroup Label=\"ProjectConfigurations\">")
    for _, targetinfo in ipairs(target.info) do
        vcxprojfile:enter("<ProjectConfiguration Include=\"%s|%s\">", targetinfo.mode, targetinfo.arch)
            vcxprojfile:print("<Configuration>%s</Configuration>", targetinfo.mode)
            vcxprojfile:print("<Platform>%s</Platform>", targetinfo.arch)
        vcxprojfile:leave("</ProjectConfiguration>")
    end
    vcxprojfile:leave("</ItemGroup>")

    -- make Globals
    vcxprojfile:enter("<PropertyGroup Label=\"Globals\">")
        vcxprojfile:print("<ProjectGuid>{%s}</ProjectGuid>", os.uuid(targetname))
        vcxprojfile:print("<RootNamespace>%s</RootNamespace>", targetname)
        if vsinfo.vstudio_version >= "2015" then
            vcxprojfile:print("<WindowsTargetPlatformVersion>%s</WindowsTargetPlatformVersion>", sdk_versions["vs" .. vsinfo.vstudio_version])
        end
    vcxprojfile:leave("</PropertyGroup>")

    -- import Microsoft.Cpp.Default.props
    vcxprojfile:print("<Import Project=\"%$(VCTargetsPath)\\Microsoft.Cpp.Default.props\" />")

    -- make Configuration
    for _, targetinfo in ipairs(target.info) do
        vcxprojfile:enter("<PropertyGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\" Label=\"Configuration\">", targetinfo.mode, targetinfo.arch)
            vcxprojfile:print("<ConfigurationType>%s</ConfigurationType>", assert(configuration_types[target.kind]))
            vcxprojfile:print("<PlatformToolset>v%s</PlatformToolset>", assert(toolset_versions["vs" .. vsinfo.vstudio_version]))
            vcxprojfile:print("<CharacterSet>MultiByte</CharacterSet>")
        vcxprojfile:leave("</PropertyGroup>")
    end

    -- import Microsoft.Cpp.props
    vcxprojfile:print("<Import Project=\"%$(VCTargetsPath)\\Microsoft.Cpp.props\" />")

    -- make ExtensionSettings
    vcxprojfile:enter("<ImportGroup Label=\"ExtensionSettings\">")
    vcxprojfile:leave("</ImportGroup>")

    -- make PropertySheets
    for _, targetinfo in ipairs(target.info) do
        vcxprojfile:enter("<ImportGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\" Label=\"PropertySheets\">", targetinfo.mode, targetinfo.arch)
            vcxprojfile:print("<Import Project=\"%$(UserRootDir)\\Microsoft.Cpp.%$(Platform).user.props\" Condition=\"exists(\'%$(UserRootDir)\\Microsoft.Cpp.%$(Platform).user.props\')\" Label=\"LocalAppDataPlatform\" />")
        vcxprojfile:leave("</ImportGroup>")
    end

    -- make UserMacros
    vcxprojfile:print("<PropertyGroup Label=\"UserMacros\" />")

    -- make OutputDirectory and IntermediateDirectory
    for _, targetinfo in ipairs(target.info) do
        vcxprojfile:enter("<PropertyGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">", targetinfo.mode, targetinfo.arch)
            vcxprojfile:print("<OutDir>%s\\</OutDir>", path.relative(path.absolute(config.get("buildir")), vcxprojdir))
            vcxprojfile:print("<IntDir>%$(Configuration)\\</IntDir>")
            if target.kind == "binary" then
                vcxprojfile:print("<LinkIncremental>true</LinkIncremental>")
            end
        vcxprojfile:leave("</PropertyGroup>")
    end
end

-- make common item 
function _make_common_item(vcxprojfile, vsinfo, targetinfo, vcxprojdir)

    -- enter ItemDefinitionGroup 
    vcxprojfile:enter("<ItemDefinitionGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">", targetinfo.mode, targetinfo.arch)
    
    -- for linker?
    if targetinfo.kind == "binary" then
        vcxprojfile:enter("<Link>")

            -- make linker flags
            local flags = table.concat(_make_linkflags(targetinfo, vcxprojdir), " "):trim()

            -- make AdditionalOptions
            vcxprojfile:print("<AdditionalOptions>%s %%(AdditionalOptions)</AdditionalOptions>", flags)

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
            vcxprojfile:print("<TargetMachine>%s</TargetMachine>", ifelse(targetinfo.arch == "x64", "MachineX64", "MachineX86"))

        vcxprojfile:leave("</Link>")
    end

    -- for compiler?
    vcxprojfile:enter("<ClCompile>")

        -- get compiler flags
        local flags = table.concat(targetinfo.commonflags, " "):trim()
           
        -- make AdditionalOptions
        vcxprojfile:print("<AdditionalOptions>%s %%(AdditionalOptions)</AdditionalOptions>", flags)

        -- make Optimization
        if flags:find("[%-|/]Od") then
            vcxprojfile:print("<Optimization>Disabled</Optimization>") 
        elseif flags:find("[%-|/]Os") or flags:find("[%-|/]O1") then
            vcxprojfile:print("<Optimization>MinSpace</Optimization>") 
        elseif flags:find("[%-|/]O2") or flags:find("[%-|/]Ot") then
            vcxprojfile:print("<Optimization>MaxSpeed</Optimization>") 
        elseif flags:find("[%-|/]Ox") then
            vcxprojfile:print("<Optimization>Full</Optimization>") 
        end

        -- make ProgramDataBaseFileName (default: empty)
        vcxprojfile:print("<ProgramDataBaseFileName></ProgramDataBaseFileName>") 

        -- complie as c++ if exists flag: /TP
        if flags:find("[%-|/]TP") then
            vcxprojfile:print("<CompileAs>CompileAsCpp</CompileAs>")
        end
    vcxprojfile:leave("</ClCompile>")

    -- leave ItemDefinitionGroup 
    vcxprojfile:leave("</ItemDefinitionGroup>")
end

-- make common items
function _make_common_items(vcxprojfile, vsinfo, target, vcxprojdir)

    -- for each mode and arch
    for _, targetinfo in ipairs(target.info) do

        -- make source flags
        local flags_stats = {}
        local files_count = 0
        local first_flags = nil
        targetinfo.sourceflags = {}
        for _, sourcefile in ipairs(targetinfo.target:sourcefiles()) do

            -- make compiler flags
            local flags = _make_compflags(sourcefile, targetinfo, vcxprojdir)
            for _, flag in ipairs(flags) do
                flags_stats[flag] = (flags_stats[flag] or 0) + 1
            end

            -- update files count
            files_count = files_count + 1

            -- save first flags
            if first_flags == nil then
                first_flags = flags
            end

            -- save source flags
            targetinfo.sourceflags[sourcefile] = flags
        end

        -- make common flags
        targetinfo.commonflags = {}
        for _, flag in ipairs(first_flags) do
            if flags_stats[flag] == files_count then
                table.insert(targetinfo.commonflags, flag)
            end
        end

        -- remove common flags from source flags
        local sourceflags = {}
        for sourcefile, flags in pairs(targetinfo.sourceflags) do
            local otherflags = {}
            for _, flag in ipairs(flags) do
                if flags_stats[flag] ~= files_count then
                    table.insert(otherflags, flag)
                end
            end
            sourceflags[sourcefile] = otherflags
        end
        targetinfo.sourceflags = sourceflags

        -- make common item
        _make_common_item(vcxprojfile, vsinfo, targetinfo, vcxprojdir)
    end
end

-- make header file
function _make_header_file(vcxprojfile, includefile, vcxprojdir)
    vcxprojfile:print("<ClInclude Include=\"%s\" />", path.relative(path.absolute(includefile), vcxprojdir))
end

-- make source file
function _make_source_file(vcxprojfile, vsinfo, sourcefile, sourceinfo, vcxprojdir)

    -- no AdditionalOptions?
    local additional = false
    local objectfile = nil
    for _, info in ipairs(sourceinfo) do
        if table.concat(info.flags, " "):trim() ~= "" or (objectfile and info.objectfile ~= objectfile) then
            additional = true
            break
        end
        objectfile = info.objectfile
    end

    -- add source file
    vcxprojfile:enter("<ClCompile Include=\"%s\">", path.relative(path.absolute(sourcefile), vcxprojdir))
        if additional then
            for _, info in ipairs(sourceinfo) do

                -- get source flags
                local flags = table.concat(info.flags, " "):trim()

                -- make AdditionalOptions 
                if flags ~= "" then 
                    vcxprojfile:print("<AdditionalOptions Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">%s %%(AdditionalOptions)</AdditionalOptions>", info.mode, info.arch, flags)
                end

                -- make ObjectFileName
                vcxprojfile:print("<ObjectFileName Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">%s</ObjectFileName>", info.mode, info.arch, path.relative(path.absolute(info.objectfile), vcxprojdir))

                -- complie as c++ if exists flag: /TP
                if flags:find("[%-|/]TP") then
                    vcxprojfile:print("<CompileAs Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">CompileAsCpp</CompileAs>", info.mode, info.arch)
                end
            end
        else
            -- make ObjectFileName
            vcxprojfile:print("<ObjectFileName>%s</ObjectFileName>", path.relative(path.absolute(objectfile), vcxprojdir))
        end
    vcxprojfile:leave("</ClCompile>")
end

-- make source files
function _make_source_files(vcxprojfile, vsinfo, target, vcxprojdir)

    -- enter ItemGroup
    vcxprojfile:enter("<ItemGroup>")

        -- make source file infos
        local sourceinfos = {}
        for _, targetinfo in ipairs(target.info) do
            for _, sourcebatch in pairs(targetinfo.target:sourcebatches()) do
                local objectfiles = sourcebatch.objectfiles
                for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    local objectfile    = objectfiles[idx]
                    local flags         = targetinfo.sourceflags[sourcefile]
                    sourceinfos[sourcefile] = sourceinfos[sourcefile] or {}
                    table.insert(sourceinfos[sourcefile], {mode = targetinfo.mode, arch = targetinfo.arch, objectfile = objectfile, flags = flags})
                end
            end
        end

        -- make source files
        for sourcefile, sourceinfo in pairs(sourceinfos) do
            _make_source_file(vcxprojfile, vsinfo, sourcefile, sourceinfo, vcxprojdir) 
        end

    vcxprojfile:leave("</ItemGroup>")

    -- enter header group
    vcxprojfile:enter("<ItemGroup>")

        -- add headers
        for _, includefile in ipairs(target.headerfiles) do
            _make_header_file(vcxprojfile, includefile, vcxprojdir)
        end
    vcxprojfile:leave("</ItemGroup>")
end

-- make vcxproj
function make(vsinfo, target)

    -- the target name
    local targetname = target.name

    -- the vcxproj directory
    local vcxprojdir = path.join(vsinfo.solution_dir, targetname)

    -- open vcxproj file
    local vcxprojfile = vsfile.open(path.join(vcxprojdir, targetname .. ".vcxproj"), "w")

    -- init indent character
    vsfile.indentchar('  ')

    -- make header
    _make_header(vcxprojfile, vsinfo)

    -- make Configurations
    _make_configurations(vcxprojfile, vsinfo, target, vcxprojdir)

    -- make common items
    _make_common_items(vcxprojfile, vsinfo, target, vcxprojdir)

    -- make source files
    _make_source_files(vcxprojfile, vsinfo, target, vcxprojdir)

    -- make tailer
    _make_tailer(vcxprojfile, vsinfo)

    -- exit solution file
    vcxprojfile:close()
end
