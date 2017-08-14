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
import("core.project.config")
import("core.language.language")
import("vsfile")

-- make compiling flags
function _make_compflags(sourcefile, targetinfo, vcxprojdir)

    -- translate path for -Idir or /Idir, -Fdsymbol.pdb or /Fdsymbol.pdb
    local flags = {}
    for _, flag in ipairs(targetinfo.compflags[sourcefile]) do

        -- -Idir or /Idir
        flag = flag:gsub("[%-|/]I(.*)", function (dir)
                        dir = dir:trim()
                        if not path.is_absolute(dir) then
                            dir = path.relative(path.absolute(dir), vcxprojdir)
                        end
                        return "/I" .. dir
                    end)

        -- save flag
        table.insert(flags, flag)
    end

    -- add -D__config_$(mode)__ and -D__config_$(arch)__ for the config header
    table.insert(flags, "-D__config_" .. targetinfo.mode .. "__")
    table.insert(flags, "-D__config_" .. targetinfo.arch .. "__")

    -- ok?
    return flags
end

-- make linking flags
function _make_linkflags(targetinfo, vcxprojdir)

    -- replace -libpath:dir or /libpath:dir
    local flags = {}
    for _, flag in ipairs(targetinfo.linkflags) do

        -- replace -libpath:dir or /libpath:dir
        flag = flag:gsub("[%-|/]libpath:(.*)", function (dir)
                        dir = dir:trim()
                        if not path.is_absolute(dir) then
                            dir = path.relative(path.absolute(dir), vcxprojdir)
                        end
                        return "/libpath:" .. dir
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

    -- the default sdk version
    local sdk_versions = 
    {
        vs2015 = "10.0.10240.0"
    ,   vs2017 = "10.0.14393.0"
    }

    -- get sdk version
    local sdkver = nil
    for _, targetinfo in ipairs(target.info) do
        sdkver = targetinfo.sdkver
        if sdkver then
            break
        end
    end

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
        vcxprojfile:print("<ProjectGuid>{%s}</ProjectGuid>", hash.uuid(targetname))
        vcxprojfile:print("<RootNamespace>%s</RootNamespace>", targetname)
        if vsinfo.vstudio_version >= "2015" then
            vcxprojfile:print("<WindowsTargetPlatformVersion>%s</WindowsTargetPlatformVersion>", sdkver or sdk_versions["vs" .. vsinfo.vstudio_version])
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
            vcxprojfile:print("<TargetName>%s</TargetName>", path.basename(targetinfo.targetfile))
            vcxprojfile:print("<TargetExt>%s</TargetExt>", path.extension(targetinfo.targetfile))
            vcxprojfile:print("<TargetPath>%s</TargetPath>", path.relative(path.absolute(targetinfo.targetfile), vcxprojdir))

            if target.kind == "binary" then
                vcxprojfile:print("<LinkIncremental>true</LinkIncremental>")
            end
        vcxprojfile:leave("</PropertyGroup>")
    end
end

-- make source options
function _make_source_options(vcxprojfile, flags, condition)

    -- exists condition?
    condition = condition or ""

    -- get flags string
    local flagstr = os.args(flags)

    -- make Optimization
    if flagstr:find("[%-|/]Os") or flagstr:find("[%-|/]O1") then
        vcxprojfile:print("<Optimization%s>MinSpace</Optimization>", condition) 
    elseif flagstr:find("[%-|/]O2") or flagstr:find("[%-|/]Ot") then
        vcxprojfile:print("<Optimization%s>MaxSpeed</Optimization>", condition) 
    elseif flagstr:find("[%-|/]Ox") then
        vcxprojfile:print("<Optimization%s>Full</Optimization>", condition) 
    else
        vcxprojfile:print("<Optimization%s>Disabled</Optimization>", condition) 
    end

    -- make FloatingPointModel
    if flagstr:find("[%-|/]fp:fast") then
        vcxprojfile:print("<FloatingPointModel%s>Fast</FloatingPointModel>", condition) 
    elseif flagstr:find("[%-|/]fp:strict") then
        vcxprojfile:print("<FloatingPointModel%s>Strict</FloatingPointModel>", condition) 
    elseif flagstr:find("[%-|/]fp:precise") then
        vcxprojfile:print("<FloatingPointModel%s>Precise</FloatingPointModel>", condition) 
    end

    -- make WarningLevel
    if flagstr:find("[%-|/]W1") then
        vcxprojfile:print("<WarningLevel%s>Level1</WarningLevel>", condition) 
    elseif flagstr:find("[%-|/]W2") then
        vcxprojfile:print("<WarningLevel%s>Level2</WarningLevel>", condition) 
    elseif flagstr:find("[%-|/]W3") then
        vcxprojfile:print("<WarningLevel%s>Level3</WarningLevel>", condition) 
    elseif flagstr:find("[%-|/]Wall") then
        vcxprojfile:print("<WarningLevel%s>EnableAllWarnings</WarningLevel>", condition) 
    else
        vcxprojfile:print("<WarningLevel%s>TurnOffAllWarnings</WarningLevel>", condition) 
    end
    if flagstr:find("[%-|/]WX") then
        vcxprojfile:print("<TreatWarningAsError%s>true</TreatWarningAsError>", condition) 
    end

    -- make DebugInformationFormat
    if flagstr:find("[%-|/]Zi") then
        vcxprojfile:print("<DebugInformationFormat%s>ProgramDatabase</DebugInformationFormat>", condition)
    elseif flagstr:find("[%-|/]ZI") then
        vcxprojfile:print("<DebugInformationFormat%s>EditAndContinue</DebugInformationFormat>", condition)
    elseif flagstr:find("[%-|/]Z7") then
        vcxprojfile:print("<DebugInformationFormat%s>OldStyle</DebugInformationFormat>", condition)
    else
        vcxprojfile:print("<DebugInformationFormat%s>None</DebugInformationFormat>", condition)
    end

    -- make RuntimeLibrary
    if flagstr:find("[%-|/]MDd") then
        vcxprojfile:print("<RuntimeLibrary%s>MultiThreadedDebugDLL</RuntimeLibrary>", condition)
    elseif flagstr:find("[%-|/]MD") then
        vcxprojfile:print("<RuntimeLibrary%s>MultiThreadedDLL</RuntimeLibrary>", condition)
    elseif flagstr:find("[%-|/]MTd") then
        vcxprojfile:print("<RuntimeLibrary%s>MultiThreadedDebug</RuntimeLibrary>", condition)
    elseif flagstr:find("[%-|/]MT") then
        vcxprojfile:print("<RuntimeLibrary%s>MultiThreaded</RuntimeLibrary>", condition)
    end

    -- complie as c++ if exists flag: /TP
    if flagstr:find("[%-|/]TP") then
        vcxprojfile:print("<CompileAs%s>CompileAsCpp</CompileAs>", condition)
    end

    -- make AdditionalOptions
    local additional_flags = {}
    local excludes = {"Os", "O0", "O1", "O2", "Ot", "Ox", "W0", "W1", "W2", "W3", "WX", "Wall", "Zi", "ZI", "Z7", "MT", "MTd", "MD", "MDd", "TP", "Fd", "fp"}
    for _, flag in ipairs(flags) do
        local excluded = false
        for _, exclude in ipairs(excludes) do
            if flag:find("[%-|/]" .. exclude) then
                excluded = true
                break
            end
        end
        if not excluded then
            table.insert(additional_flags, flag)
        end
    end
    if #additional_flags > 0 then
        vcxprojfile:print("<AdditionalOptions%s>%s %%(AdditionalOptions)</AdditionalOptions>", condition, os.args(additional_flags))
    end
end

-- make common item 
function _make_common_item(vcxprojfile, vsinfo, target, targetinfo, vcxprojdir)

    -- enter ItemDefinitionGroup 
    vcxprojfile:enter("<ItemDefinitionGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">", targetinfo.mode, targetinfo.arch)
    
    -- init the linker kinds
    local linkerkinds = 
    {
        binary = "Link"
    ,   static = "Lib"
    ,   shared = "Link"
    }

    -- for linker?
    vcxprojfile:enter("<%s>", linkerkinds[targetinfo.targetkind])

        -- make linker flags
        local flags = {}
        for _, flag in ipairs(_make_linkflags(targetinfo, vcxprojdir)) do

            -- remove "-machine:[x86|x64]", "-pdb:*.pdb" and "-debug"
            if not flag:find("[%-/]machine:%w+") and not flag:find("[%-/]pdb:.+%.pdb") and not flag:find("[%-/]debug") then
                table.insert(flags, flag)
            end
        end
        flags = os.args(flags)

        -- make AdditionalOptions
        vcxprojfile:print("<AdditionalOptions>%s %%(AdditionalOptions)</AdditionalOptions>", flags)

        -- generate debug infomation?
        if linkerkinds[targetinfo.targetkind] == "Link" then

            -- enable debug infomation?
            local debug = false
            for _, symbol in ipairs(targetinfo.symbols) do
                if symbol == "debug" then
                    debug = true
                    break
                end
            end
            vcxprojfile:print("<GenerateDebugInformation>%s</GenerateDebugInformation>", tostring(debug))

            -- make *.pdb file path
            local symbolfile = targetinfo.symbolfile
            if symbolfile then
                vcxprojfile:print("<ProgramDatabaseFile>%s</ProgramDatabaseFile>", path.relative(path.absolute(symbolfile), vcxprojdir))
            end
        end

        -- make SubSystem
        if targetinfo.targetkind == "binary" then
            vcxprojfile:print("<SubSystem>Console</SubSystem>")
        end
    
        -- make TargetMachine
        vcxprojfile:print("<TargetMachine>%s</TargetMachine>", ifelse(targetinfo.arch == "x64", "MachineX64", "MachineX86"))

        -- make OutputFile
        vcxprojfile:print("<OutputFile>%s</OutputFile>", path.relative(path.absolute(targetinfo.targetfile), vcxprojdir))

    vcxprojfile:leave("</%s>", linkerkinds[targetinfo.targetkind])

    -- for compiler?
    vcxprojfile:enter("<ClCompile>")

        -- make source options
        _make_source_options(vcxprojfile, targetinfo.commonflags)

        -- make *.pdb file path
        local symbolfile = targetinfo.symbolfile
        if symbolfile then
            vcxprojfile:print("<ProgramDatabaseFile>%s</ProgramDatabaseFile>", path.relative(path.absolute(symbolfile), vcxprojdir))
        end

        -- use c or c++ precompiled header
        local pcheader = target.pcxxheader or target.pcheader
        if pcheader then 

            -- make precompiled header and outputfile
            vcxprojfile:print("<PrecompiledHeader>Use</PrecompiledHeader>")
            vcxprojfile:print("<PrecompiledHeaderFile>%s</PrecompiledHeaderFile>", path.filename(pcheader))
            local pcoutputfile = targetinfo.pcxxoutputfile or targetinfo.pcoutputfile
            if pcoutputfile then
                vcxprojfile:print("<PrecompiledHeaderOutputFile>%s</PrecompiledHeaderOutputFile>", path.relative(path.absolute(pcoutputfile), vcxprojdir))
            end
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
        for sourcekind, sourcebatch in pairs(targetinfo.sourcebatches) do
            if sourcekind == "cc" or sourcekind == "cxx" or sourcekind == "as" then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do

                    -- make compiler flags
                    local flags = _make_compflags(sourcefile, targetinfo, vcxprojdir)

                    -- no common flags for asm
                    if sourcekind ~= "as" then
                        for _, flag in ipairs(flags) do
                            flags_stats[flag] = (flags_stats[flag] or 0) + 1
                        end

                        -- update files count
                        files_count = files_count + 1

                        -- save first flags
                        if first_flags == nil then
                            first_flags = flags
                        end
                    end

                    -- save source flags
                    targetinfo.sourceflags[sourcefile] = flags
                end
            end
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
        _make_common_item(vcxprojfile, vsinfo, target, targetinfo, vcxprojdir)
    end
end

-- make header file
function _make_header_file(vcxprojfile, includefile, vcxprojdir)
    vcxprojfile:print("<ClInclude Include=\"%s\" />", path.relative(path.absolute(includefile), vcxprojdir))
end

-- make source file for all modes
function _make_source_file_forall(vcxprojfile, vsinfo, target, sourcefile, sourceinfo, vcxprojdir)

    -- get object file and source kind 
    local sourcekind = nil
    for _, info in ipairs(sourceinfo) do
        sourcekind = info.sourcekind
        break
    end

    -- enter it
    sourcefile = path.relative(path.absolute(sourcefile), vcxprojdir)
    vcxprojfile:enter("<%s Include=\"%s\">", ifelse(sourcekind == "as", "CustomBuild", "ClCompile"), sourcefile)

        -- for *.asm files
        if sourcekind == "as" then
            vcxprojfile:print("<ExcludedFromBuild>false</ExcludedFromBuild>")
            vcxprojfile:print("<FileType>Document</FileType>")
            for _, info in ipairs(sourceinfo) do
                local objectfile = path.relative(path.absolute(info.objectfile), vcxprojdir)
                vcxprojfile:print("<Outputs Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s\'\">%s</Outputs>", info.mode .. '|' .. info.arch, objectfile)
                vcxprojfile:print("<Command Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s\'\">%s /nologo /c %s -Fo%s %s</Command>", info.mode .. '|' .. info.arch, ifelse(info.arch == "x64", "ml64", "ml"), os.args(info.flags), objectfile, sourcefile)
            end

        -- for *.c/cpp files
        else

            -- init items
            local items = 
            {
                AdditionalOptions = 
                {
                    key = function (info) return os.args(info.flags) end
                ,   value = function (key) return key .. " %%(AdditionalOptions)" end
                }
            ,   ObjectFileName =
                {
                    key = function (info) return path.relative(path.absolute(info.objectfile), vcxprojdir) end
                ,   value = function (key) return key end
                }
            }
        
            -- make items
            for itemname, iteminfo in pairs(items) do

                -- make merge keys
                local mergekeys  = {}
                for _, info in ipairs(sourceinfo) do
                    local key = iteminfo.key(info)
                    mergekeys[key] = mergekeys[key] or {}
                    mergekeys[key][info.mode .. '|' .. info.arch] = true
                end
                for key, mergeinfos in pairs(mergekeys) do

                    -- merge mode and arch first
                    local count = 0
                    for _, mode in ipairs(vsinfo.modes) do
                        if mergeinfos[mode .. "|Win32"] and mergeinfos[mode .. "|x64"] then
                            mergeinfos[mode .. "|Win32"] = nil
                            mergeinfos[mode .. "|x64"]   = nil
                            mergeinfos[mode]             = true
                        end
                        if mergeinfos[mode] then
                            count = count + 1
                        end
                    end

                    -- disable the precompiled header if sourcekind ~= headerkind
                    local pcheader = target.pcxxheader or target.pcheader
                    local pcheader_disable = false
                    if pcheader and language.sourcekind_of(sourcefile) ~= ifelse(target.pcxxheader, "cxx", "cc") then
                        pcheader_disable = true
                    end

                    -- all modes and archs exist?
                    if count == #vsinfo.modes then
                        if #key > 0 then
                            vcxprojfile:print("<%s>%s</%s>", itemname, iteminfo.value(key), itemname)
                            if pcheader_disable then
                                vcxprojfile:print("<PrecompiledHeader>NotUsing</PrecompiledHeader>")
                            end
                        end
                    else
                        for cond, _ in pairs(mergeinfos) do
                            if cond:find('|', 1, true) then
                                -- for mode | arch
                                if #key > 0 then
                                    vcxprojfile:print("<%s Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s\'\">%s</%s>", itemname, cond, iteminfo.value(key), itemname)
                                    if pcheader_disable then
                                        vcxprojfile:print("<PrecompiledHeader Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s\'\">NotUsing</PrecompiledHeader>", cond)
                                    end
                                end
                            else
                                -- only for mode
                                if #key > 0 then
                                    vcxprojfile:print("<%s Condition=\"\'%$(Configuration)\'==\'%s\'\">%s</%s>", itemname, cond, iteminfo.value(key), itemname)
                                    if pcheader_disable then
                                        vcxprojfile:print("<PrecompiledHeader Condition=\"\'%$(Configuration)\'==\'%s\'\">NotUsing</PrecompiledHeader>", cond)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

    -- leave it
    vcxprojfile:leave("</%s>", ifelse(sourcekind == "as", "CustomBuild", "ClCompile"))
end

-- make source file for specific modes
function _make_source_file_forspec(vcxprojfile, vsinfo, target, sourcefile, sourceinfo, vcxprojdir)

    -- add source file
    sourcefile = path.relative(path.absolute(sourcefile), vcxprojdir)
    for _, info in ipairs(sourceinfo) do

        -- enter it
        vcxprojfile:enter("<%s Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\" Include=\"%s\">", ifelse(info.sourcekind == "as", "CustomBuild", "ClCompile"), info.mode, info.arch, sourcefile)

        -- for *.asm files
        local objectfile = path.relative(path.absolute(info.objectfile), vcxprojdir)
        if info.sourcekind == "as" then 
            vcxprojfile:print("<ExcludedFromBuild>false</ExcludedFromBuild>")
            vcxprojfile:print("<FileType>Document</FileType>")
            vcxprojfile:print("<Outputs>%s</Outputs>", objectfile)
            vcxprojfile:print("<Command>%s /nologo /c %s -Fo%s %s</Command>", ifelse(info.arch == "x64", "ml64", "ml"), os.args(info.flags), objectfile, sourcefile)

        -- for *.c/cpp files
        else

            -- disable the precompiled header if sourcekind ~= headerkind
            local pcheader = target.pcxxheader or target.pcheader
            if pcheader and language.sourcekind_of(sourcefile) ~= ifelse(target.pcxxheader, "cxx", "cc") then
                vcxprojfile:print("<PrecompiledHeader>NotUsing</PrecompiledHeader>")
            end
            vcxprojfile:print("<ObjectFileName>%s</ObjectFileName>", objectfile)
            vcxprojfile:print("<AdditionalOptions>%s %%(AdditionalOptions)</AdditionalOptions>", os.args(info.flags))
        end

        -- leave it
        vcxprojfile:leave("</%s>", ifelse(info.sourcekind == "as", "CustomBuild", "ClCompile"))
    end
end

-- make source file for precompiled header 
function _make_source_file_forpch(vcxprojfile, vsinfo, target, vcxprojdir)

    -- add precompiled source file
    local pcheader = target.pcxxheader or target.pcheader
    if pcheader then
        local sourcefile = path.relative(path.absolute(pcheader), vcxprojdir)
        vcxprojfile:enter("<ClCompile Include=\"%s\">", sourcefile)
            vcxprojfile:print("<PrecompiledHeader>Create</PrecompiledHeader>")
            vcxprojfile:print("<PrecompiledHeaderFile></PrecompiledHeaderFile>")
            vcxprojfile:print("<AdditionalOptions> %%(AdditionalOptions)</AdditionalOptions>")
            for _, info in ipairs(target.info) do

                -- compile as c/c++
                local compileas = ifelse(target.pcxxheader, "CompileAsCpp", "CompileAsC")
                vcxprojfile:print("<CompileAs Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">%s</CompileAs>", info.mode, info.arch, compileas)

                -- add object file
                local pcoutputfile = info.pcxxoutputfile or info.pcoutputfile
                if pcoutputfile then
                    local objectfile = path.relative(path.absolute(pcoutputfile .. ".obj"), vcxprojdir)
                    vcxprojfile:print("<ObjectFileName Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">%s</ObjectFileName>", info.mode, info.arch, objectfile)
                end
            end
        vcxprojfile:leave("</ClCompile>")
    end
end

-- make source files
function _make_source_files(vcxprojfile, vsinfo, target, vcxprojdir)

    -- add source files
    vcxprojfile:enter("<ItemGroup>")

        -- make source file infos
        local sourceinfos = {}
        for _, targetinfo in ipairs(target.info) do
            for sourcekind, sourcebatch in pairs(targetinfo.sourcebatches) do
                if sourcekind == "cc" or sourcekind == "cxx" or sourcekind == "as" then
                    local objectfiles = sourcebatch.objectfiles
                    for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
                        local objectfile    = objectfiles[idx]
                        local flags         = targetinfo.sourceflags[sourcefile]
                        sourceinfos[sourcefile] = sourceinfos[sourcefile] or {}
                        table.insert(sourceinfos[sourcefile], {mode = targetinfo.mode, arch = targetinfo.arch, sourcekind = sourcekind, objectfile = objectfile, flags = flags})
                    end
                end
            end
        end

        -- make source files
        for sourcefile, sourceinfo in pairs(sourceinfos) do
            if #sourceinfo == #target.info then
                _make_source_file_forall(vcxprojfile, vsinfo, target, sourcefile, sourceinfo, vcxprojdir) 
            else
                _make_source_file_forspec(vcxprojfile, vsinfo, target, sourcefile, sourceinfo, vcxprojdir) 
            end
        end

        -- make precompiled source file
        _make_source_file_forpch(vcxprojfile, vsinfo, target, vcxprojdir) 

    vcxprojfile:leave("</ItemGroup>")

    -- add headers
    vcxprojfile:enter("<ItemGroup>")
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
