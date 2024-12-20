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
-- @file        vs201x_vcxproj.lua
--

-- imports
import("core.base.hashset")
import("core.project.rule")
import("core.project.config")
import("core.project.project")
import("core.language.language")
import("core.tool.toolchain")
import("private.utils.batchcmds")
import("detect.sdks.find_cuda")
import("vsfile")
import("vsutils")
import("private.utils.toolchain", {alias = "toolchain_utils"})

function _make_dirs(dir, vcxprojdir)
    dir = dir:trim()
    if #dir == 0 then
        return ""
    end
    dir = path.translate(dir)
    if not path.is_absolute(dir) then
        dir = path.relative(path.absolute(dir), vcxprojdir)
    end
    return dir
end

-- check for CUDA
function _check_cuda(target)
    local cuda
    for _, targetinfo in ipairs(target.info) do
        if targetinfo.sourcekinds and table.contains(targetinfo.sourcekinds, "cu") then
            cuda = find_cuda()
            break
        end
    end
    if cuda then
        if cuda.msbuildextensionsdir and cuda.version and os.isfile(path.join(cuda.msbuildextensionsdir, format("CUDA %s.props", cuda.version))) then
            return cuda
        else
            os.raise("The Visual Studio Integration for CUDA %s is not found. Please check your CUDA installation.", cuda.version)
        end
    end
end

-- get toolset version
function _get_toolset_ver(targetinfo, vsinfo)
    -- get toolset version from vs version
    local vs_toolset = toolchain.load("msvc"):config("vs_toolset") or config.get("vs_toolset")
    local toolset_ver = toolchain_utils.get_vs_toolset_ver(vs_toolset)
    if not toolset_ver then
        toolset_ver = vsinfo.toolset_version
    end
    return toolset_ver
end

-- get platform sdk version from vcvars.WindowsSDKVersion
function _get_platform_sdkver(target, vsinfo)
    local sdkver = nil
    for _, targetinfo in ipairs(target.info) do
        sdkver = targetinfo.sdkver
        if sdkver then
            break
        end
    end
    return sdkver or vsinfo.sdk_version
end

-- combine two successive flags
function _combine_flags(flags, patterns)
    local newflags = {}
    local temparg
    for _, arg in ipairs(flags) do
        if temparg then
            table.insert(newflags, temparg .. " " .. arg)
            temparg = nil
        else
            for _, pattern in ipairs(patterns) do
                if arg:match(pattern) then
                    temparg = arg
                end
            end
            if not temparg then
                table.insert(newflags, arg)
            end
        end
    end
    return newflags
end

-- exclude patterns from flags
function _exclude_flags(flags, excludes)
    local newflags = {}
    for _, flag in ipairs(flags) do
        local excluded = false
        for _, exclude in ipairs(excludes) do
            if flag:find("^[%-/]" .. exclude) then
                excluded = true
                break
            end
        end
        if not excluded then
            table.insert(newflags, vsutils.escape(flag))
        end
    end
    return newflags
end

-- try split from nvcc -code flag
--   e.g. nvcc -arch=compute_86 -code=\"sm_86,compute_86\"
--        nvcc -gencode arch=compute_86,code=[sm_86,compute_86]
function _split_gpucodes(flag)
    flag = flag:gsub("[%[\"]?(.-)[%]\"]?", "%1")
    return flag:split(",")
end

-- is module file?
function _is_modulefile(sourcefile)
    local extension = path.extension(sourcefile)
    return extension == ".mpp" or extension == ".mxx" or extension == ".cppm" or extension == ".ixx"
end

-- make compiling command
function _make_compcmd(compargv, sourcefile, objectfile, vcxprojdir)
    local argv = {}
    for i, v in ipairs(compargv) do
        if i == 1 then
            v = path.filename(v) -- C:\xxx\ml.exe -> ml.exe
        end
        v = v:gsub("__sourcefile__", sourcefile)
        v = v:gsub("__objectfile__", objectfile)

        -- -Idir or /Idir
        -- handle external includes as well
        for _, pattern in ipairs({"[%-/](I)(.*)", "[%-/](external:I)(.*)"}) do
            v = v:gsub(pattern, function (flag, dir)
                dir = _make_dirs(dir, vcxprojdir)
                return "/" .. flag .. dir
            end)
        end

        table.insert(argv, v)
    end
    return table.concat(argv, " ")
end

-- make compiling flags
function _make_compflags(sourcefile, targetinfo, vcxprojdir)

    -- translate path for -Idir or /Idir
    local flags = {}
    for _, flag in ipairs(targetinfo.compflags[sourcefile]) do
        for _, pattern in ipairs({"[%-/](I)(.*)", "[%-/](external:I)(.*)"}) do

            -- -Idir or /Idir
            flag = flag:gsub(pattern, function (flag, dir)
                dir = _make_dirs(dir, vcxprojdir)
                return "/" .. flag .. dir
            end)
        end
        table.insert(flags, flag)
    end

    -- add -D__config_$(mode)__ and -D__config_$(arch)__ for the config header
    table.insert(flags, "-D__config_" .. targetinfo.mode .. "__")
    table.insert(flags, "-D__config_" .. targetinfo.arch .. "__")
    return flags
end

-- make linking flags
function _make_linkflags(targetinfo, vcxprojdir)

    -- replace -libpath:dir or /libpath:dir
    local flags = {}
    for _, flag in ipairs(targetinfo.linkflags) do

        -- replace -libpath:dir or /libpath:dir
        flag = flag:gsub(string.ipattern("[%-/]libpath:(.*)"), function (dir)
            dir = _make_dirs(dir, vcxprojdir)
            return "/libpath:" .. dir
        end)

        -- replace -def:dir or /def:dir
        flag = flag:gsub(string.ipattern("[%-/]def:(.*)"), function (dir)
            dir = _make_dirs(dir, vcxprojdir)
            return "/def:" .. dir
        end)

        -- save flag
        table.insert(flags, flag)
    end

    -- ok?
    return flags
end

-- make header
function _make_header(vcxprojfile, vsinfo)
    vcxprojfile:print("<?xml version=\"1.0\" encoding=\"utf-8\"?>")
    vcxprojfile:enter("<Project DefaultTargets=\"Build\" ToolsVersion=\"%s.0\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">", assert(vsinfo.project_version))
end

-- make references
function _make_references(vcxprojfile, vsinfo, target)
    vcxprojfile:print("<ItemGroup>")
    for dep_name, dep_vcxprojfile in pairs(target.deps) do
        vcxprojfile:print("<ProjectReference Include=\"%s\">", dep_vcxprojfile)
            vcxprojfile:print("<Project>{%s}</Project>", hash.uuid4(dep_name))
        vcxprojfile:print("</ProjectReference>")
    end
    vcxprojfile:print("</ItemGroup>")
end

-- make tailer
function _make_tailer(vcxprojfile, vsinfo, target)
    vcxprojfile:print("<Import Project=\"%$(VCTargetsPath)\\Microsoft.Cpp.targets\" />")
    vcxprojfile:enter("<ImportGroup Label=\"ExtensionTargets\">")
    local cuda = _check_cuda(target)
    if cuda then
        vcxprojfile:print("<Import Project=\"%s\" />", path.join(cuda.msbuildextensionsdir, format("CUDA %s.targets", cuda.version)))
    end
    vcxprojfile:leave("</ImportGroup>")
    vcxprojfile:leave("</Project>")
end

-- make Configurations
function _make_configurations(vcxprojfile, vsinfo, target)

    -- the target name
    local targetname = target.name

    -- init configuration type
    local configuration_types =
    {
        binary = "Application"
    ,   shared = "DynamicLibrary"
    ,   static = "StaticLibrary"
    ,   moduleonly = "StaticLibrary" -- emulate moduleonly with staticlib
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
        vcxprojfile:print("<ProjectGuid>{%s}</ProjectGuid>", hash.uuid4(targetname))
        vcxprojfile:print("<RootNamespace>%s</RootNamespace>", targetname)
        if vsinfo.vstudio_version >= "2015" then
            vcxprojfile:print("<WindowsTargetPlatformVersion>%s</WindowsTargetPlatformVersion>", _get_platform_sdkver(target, vsinfo))
        end
    vcxprojfile:leave("</PropertyGroup>")

    -- import Microsoft.Cpp.Default.props
    vcxprojfile:print("<Import Project=\"%$(VCTargetsPath)\\Microsoft.Cpp.Default.props\" />")

    -- make Configuration
    for _, targetinfo in ipairs(target.info) do
        vcxprojfile:enter("<PropertyGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\" Label=\"Configuration\">", targetinfo.mode, targetinfo.arch)
            vcxprojfile:print("<ConfigurationType>%s</ConfigurationType>", configuration_types[target.kind] or "Unknown")
            vcxprojfile:print("<PlatformToolset>%s</PlatformToolset>", _get_toolset_ver(targetinfo, vsinfo))
            vcxprojfile:print("<CharacterSet>%s</CharacterSet>", targetinfo.unicode and "Unicode" or "MultiByte")
            if targetinfo.usemfc then
                vcxprojfile:print("<UseOfMfc>%s</UseOfMfc>", targetinfo.usemfc)
            end
        vcxprojfile:leave("</PropertyGroup>")
    end

    -- import Microsoft.Cpp.props
    vcxprojfile:print("<Import Project=\"%$(VCTargetsPath)\\Microsoft.Cpp.props\" />")

    -- make ExtensionSettings
    vcxprojfile:enter("<ImportGroup Label=\"ExtensionSettings\">")
    local cuda = _check_cuda(target)
    if cuda then
        vcxprojfile:print("<Import Project=\"%s\" />", path.join(cuda.msbuildextensionsdir, format("CUDA %s.props", cuda.version)))
    end
    vcxprojfile:leave("</ImportGroup>")

    -- make PropertySheets
    for _, targetinfo in ipairs(target.info) do
        vcxprojfile:enter("<ImportGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\" Label=\"PropertySheets\">", targetinfo.mode, targetinfo.arch)
            vcxprojfile:print("<Import Project=\"%$(UserRootDir)\\Microsoft.Cpp.%$(Platform).user.props\" Condition=\"exists(\'%$(UserRootDir)\\Microsoft.Cpp.%$(Platform).user.props\')\" Label=\"LocalAppDataPlatform\" />")
        vcxprojfile:leave("</ImportGroup>")
    end

    -- make UserMacros
    vcxprojfile:print("<PropertyGroup Label=\"UserMacros\" />")
    if not configuration_types[target.kind] then
        return
    end

    -- make OutputDirectory and IntermediateDirectory
    for _, targetinfo in ipairs(target.info) do
        vcxprojfile:enter("<PropertyGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">", targetinfo.mode, targetinfo.arch)
            vcxprojfile:print("<OutDir>%s\\</OutDir>", _make_dirs(targetinfo.targetdir, target.project_dir))
            vcxprojfile:print("<IntDir>%s\\</IntDir>", _make_dirs(targetinfo.objectdir, target.project_dir))
            if targetinfo.targetfile then 
                vcxprojfile:print("<TargetName>%s</TargetName>", path.basename(targetinfo.targetfile))
                vcxprojfile:print("<TargetExt>%s</TargetExt>", path.extension(targetinfo.targetfile))
            end

            if target.kind == "binary" then
                vcxprojfile:print("<LinkIncremental>true</LinkIncremental>")
            end

            if targetinfo.manifest_embed ~= nil then
                vcxprojfile:print("<EmbedManifest>%s</EmbedManifest>", targetinfo.manifest_embed)
            end

            -- handle ExternalIncludePath (should we handle IncludePath here too?)
            local externaldirs = {}
            for _, flag in ipairs(targetinfo.commonflags.cl) do
                flag:gsub("[%-/]external:I(.*)", function (dir) table.insert(externaldirs, dir) end)
            end
            if #externaldirs > 0 then
                vcxprojfile:print("<ExternalIncludePath>%s;$(VC_IncludePath);$(WindowsSDK_IncludePath);</ExternalIncludePath>", table.concat(externaldirs, ";"))
            end
        vcxprojfile:leave("</PropertyGroup>")
    end

    -- make Debugger
    for _, targetinfo in ipairs(target.info) do
        vcxprojfile:enter("<PropertyGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\" Label=\"Debugger\">", targetinfo.mode, targetinfo.arch)
            vcxprojfile:print("<LocalDebuggerWorkingDirectory>%s</LocalDebuggerWorkingDirectory>", _make_dirs(targetinfo.rundir, target.project_dir))
            -- @note we use writef to avoid escape $() in runenvs, e.g. $([System.Environment]::Get ..)
            vcxprojfile:writef("<LocalDebuggerEnvironment>%s;%%(LocalDebuggerEnvironment)</LocalDebuggerEnvironment>\n", targetinfo.runenvs)
        vcxprojfile:leave("</PropertyGroup>")
    end
end

-- make source options for cl
function _make_source_options_cl(vcxprojfile, flags, condition)

    -- exists condition?
    condition = condition or ""

    -- get flags string
    local flagstr = os.args(flags)

    -- make Optimization
    if flagstr:find("[%-/]Os") or flagstr:find("[%-/]O1") then
        vcxprojfile:print("<Optimization%s>MinSpace</Optimization>", condition)
    elseif flagstr:find("[%-/]O2") or flagstr:find("[%-/]Ot") then
        vcxprojfile:print("<Optimization%s>MaxSpeed</Optimization>", condition)
    elseif flagstr:find("[%-/]Ox") then
        vcxprojfile:print("<Optimization%s>Full</Optimization>", condition)
    else
        vcxprojfile:print("<Optimization%s>Disabled</Optimization>", condition)
    end

    -- make FloatingPointModel
    if flagstr:find("[%-/]fp:fast") then
        vcxprojfile:print("<FloatingPointModel%s>Fast</FloatingPointModel>", condition)
    elseif flagstr:find("[%-/]fp:strict") then
        vcxprojfile:print("<FloatingPointModel%s>Strict</FloatingPointModel>", condition)
    elseif flagstr:find("[%-/]fp:precise") then
        vcxprojfile:print("<FloatingPointModel%s>Precise</FloatingPointModel>", condition)
    end

    -- make WarningLevel
    if flagstr:find("[%-/]W1") then
        vcxprojfile:print("<WarningLevel%s>Level1</WarningLevel>", condition)
    elseif flagstr:find("[%-/]W2") then
        vcxprojfile:print("<WarningLevel%s>Level2</WarningLevel>", condition)
    elseif flagstr:find("[%-/]W3") then
        vcxprojfile:print("<WarningLevel%s>Level3</WarningLevel>", condition)
    elseif flagstr:find("[%-/]W4") then
        vcxprojfile:print("<WarningLevel%s>Level4</WarningLevel>", condition)
    elseif flagstr:find("[%-/]Wall") then
        vcxprojfile:print("<WarningLevel%s>EnableAllWarnings</WarningLevel>", condition)
    else
        vcxprojfile:print("<WarningLevel%s>TurnOffAllWarnings</WarningLevel>", condition)
    end
    if flagstr:find("[%-/]WX") then
        vcxprojfile:print("<TreatWarningAsError%s>true</TreatWarningAsError>", condition)
    end

    -- make ExternalWarningLevel
    if flagstr:find("[%-/]external:W1") then
        vcxprojfile:print("<ExternalWarningLevel%s>Level1</ExternalWarningLevel>", condition)
    elseif flagstr:find("[%-/]external:W2") then
        vcxprojfile:print("<ExternalWarningLevel%s>Level2</ExternalWarningLevel>", condition)
    elseif flagstr:find("[%-/]external:W3") then
        vcxprojfile:print("<ExternalWarningLevel%s>Level3</ExternalWarningLevel>", condition)
    elseif flagstr:find("[%-/]external:W4") then
        vcxprojfile:print("<ExternalWarningLevel%s>Level4</ExternalWarningLevel>", condition)
    else
        vcxprojfile:print("<ExternalWarningLevel%s>TurnOffAllWarnings</ExternalWarningLevel>", condition)
    end

    -- make ExternalTemplatesDiagnostics
    if flagstr:find("[%-/]external:templates%-") then
        vcxprojfile:print("<ExternalTemplatesDiagnostics%s>true</ExternalTemplatesDiagnostics>", condition)
    else
        vcxprojfile:print("<ExternalTemplatesDiagnostics%s>false</ExternalTemplatesDiagnostics>", condition)
    end

    -- make DisableSpecificWarnings
    local disabledwarnings = {}
    for _, flag in ipairs(flags) do
        flag:gsub("[%-/]wd(%d+)", function (warn) table.insert(disabledwarnings, warn) end)
    end
    if #disabledwarnings > 0 then
        vcxprojfile:print("<DisableSpecificWarnings>%s;%%(DisableSpecificWarnings)</DisableSpecificWarnings>", table.concat(disabledwarnings, ";"))
    end

    -- make PreprocessorDefinitions
    local defstr = ""
    for _, flag in ipairs(flags) do
        flag:gsub("^[%-/]D(.*)",
            function (def)
                defstr = defstr .. vsutils.escape(def) .. ";"
            end
        )
    end
    defstr = defstr .. "%%(PreprocessorDefinitions)"
    vcxprojfile:print("<PreprocessorDefinitions%s>%s</PreprocessorDefinitions>", condition, defstr)

    -- make DebugInformationFormat
    if flagstr:find("[%-/]Zi") then
        vcxprojfile:print("<DebugInformationFormat%s>ProgramDatabase</DebugInformationFormat>", condition)
    elseif flagstr:find("[%-/]ZI") then
        vcxprojfile:print("<DebugInformationFormat%s>EditAndContinue</DebugInformationFormat>", condition)
    elseif flagstr:find("[%-/]Z7") then
        vcxprojfile:print("<DebugInformationFormat%s>OldStyle</DebugInformationFormat>", condition)
    else
        vcxprojfile:print("<DebugInformationFormat%s>None</DebugInformationFormat>", condition)
    end

    -- make RuntimeLibrary
    if flagstr:find("[%-/]MDd") then
        vcxprojfile:print("<RuntimeLibrary%s>MultiThreadedDebugDLL</RuntimeLibrary>", condition)
    elseif flagstr:find("[%-/]MD") then
        vcxprojfile:print("<RuntimeLibrary%s>MultiThreadedDLL</RuntimeLibrary>", condition)
    elseif flagstr:find("[%-/]MTd") then
        vcxprojfile:print("<RuntimeLibrary%s>MultiThreadedDebug</RuntimeLibrary>", condition)
    else
        vcxprojfile:print("<RuntimeLibrary%s>MultiThreaded</RuntimeLibrary>", condition)
    end

    -- make RuntimeTypeInfo
    if flagstr:find("[%-/]GR%-") then
        vcxprojfile:print("<RuntimeTypeInfo%s>false</RuntimeTypeInfo>", condition)
    elseif flagstr:find("[%-/]GR") then
        vcxprojfile:print("<RuntimeTypeInfo%s>true</RuntimeTypeInfo>", condition)
    end

    -- handle multi processor compilation
    if flagstr:find("[%-/]Gm%-") or not flagstr:find("[%-/]Gm") then
        vcxprojfile:print("<MinimalRebuild%s>false</MinimalRebuild>", condition)
        if not flagstr:find("[%-/]MP1") then
            vcxprojfile:print("<MultiProcessorCompilation%s>true</MultiProcessorCompilation>", condition)
        end
    end

    -- make AdditionalIncludeDirectories
    if flagstr:find("[%-/]I") then
        local dirs = {}
        for _, flag in ipairs(flags) do
            flag:gsub("^[%-/]I(.*)", function (dir) table.insert(dirs, vsutils.escape(dir)) end)
        end
        if #dirs > 0 then
            vcxprojfile:print("<AdditionalIncludeDirectories%s>%s</AdditionalIncludeDirectories>", condition, table.concat(dirs, ";"))
        end
    end

    -- compile as c++ if exists flag: /TP
    if flagstr:find("[%-/]TP") then
        vcxprojfile:print("<CompileAs%s>CompileAsCpp</CompileAs>", condition)
    end


    -- make SDLCheck flag: /sdl
    if flagstr:find("[%-/]sdl") then
        if flagstr:find("[%-/]sdl%-") then
            vcxprojfile:print("<SDLCheck%s>false</SDLCheck>", condition)
        else
            vcxprojfile:print("<SDLCheck%s>true</SDLCheck>", condition)
        end
    end

    -- make RemoveUnreferencedCodeData flag: Zc:inline
    if flagstr:find("[%-/]Zc:inline") then
        if flagstr:find("[%-/]Zc:inline%-") then
            vcxprojfile:print("<RemoveUnreferencedCodeData%s>false</RemoveUnreferencedCodeData>", condition)
        else
            vcxprojfile:print("<RemoveUnreferencedCodeData%s>true</RemoveUnreferencedCodeData>", condition)
        end
    end

    -- make ExceptionHandling flag:
    if flagstr:find("[%-/]EH[asc]+%-?") then
        local args = flagstr:match("[%-/]EH([asc]+%-?)")
        -- remove the last arg if flag endwith `-`
        if args and args:endswith("-") then
            args = args:sub(1, -2)
        end
        if args and args:find("a", 1, true) then
            -- a will overwrite s and c
            vcxprojfile:print("<ExceptionHandling%s>Async</ExceptionHandling>", condition)
        elseif args == "sc" or args == "cs" then
            vcxprojfile:print("<ExceptionHandling%s>Sync</ExceptionHandling>", condition)
        elseif args == "s" then
            vcxprojfile:print("<ExceptionHandling%s>SyncCThrow</ExceptionHandling>", condition)
        else
            -- if args == "c"
            -- c is ignored without s or a, do nothing here
        end
    end

    -- make AdditionalOptions
    local excludes = {
        "Od", "Os", "O0", "O1", "O2", "Ot", "Ox", "W0", "W1", "W2", "W3", "W4", "WX", "Wall", "Zi", "ZI", "Z7", "MT", "MTd", "MD", "MDd", "TP",
        "Fd", "fp", "I", "D", "Gm%-", "Gm", "GR%-", "GR", "MP", "external:W0", "external:W1", "external:W2", "external:W3", "external:W4", "external:templates%-?", "external:I",
        "std:c11", "std:c17", "std:c%+%+11", "std:c%+%+14", "std:c%+%+17", "std:c%+%+20", "std:c%+%+latest", "nologo", "wd(%d+)", "sdl%-?", "Zc:inline%-?", "EH[asc]+%-?"
    }
    local additional_flags = _exclude_flags(flags, excludes)
    if #additional_flags > 0 then
        vcxprojfile:print("<AdditionalOptions%s>%s %%(AdditionalOptions)</AdditionalOptions>", condition, os.args(additional_flags))
    end
end

-- make source options for cl
function _make_resource_options_cl(vcxprojfile, flags)

    -- get flags string
    local flagstr = os.args(flags)

    -- make PreprocessorDefinitions
    local defstr = ""
    for _, flag in ipairs(flags) do
        flag:gsub("^[%-/]D(.*)",
            function (def)
                defstr = defstr .. vsutils.escape(def) .. ";"
            end
        )
    end
    defstr = defstr .. "%%(PreprocessorDefinitions)"
    vcxprojfile:print("<PreprocessorDefinitions>%s</PreprocessorDefinitions>", defstr)

    -- make AdditionalIncludeDirectories
    if flagstr:find("[%-/]I") then
        local dirs = {}
        for _, flag in ipairs(flags) do
            flag:gsub("^[%-/]I(.*)", function (dir) table.insert(dirs, vsutils.escape(dir)) end)
        end
        if #dirs > 0 then
            vcxprojfile:print("<AdditionalIncludeDirectories>%s</AdditionalIncludeDirectories>", table.concat(dirs, ";"))
        end
    end
end

-- make source options for cuda
function _make_source_options_cuda(vcxprojfile, flags, opt)

    -- exists condition?
    condition = (opt and opt.condition) or ""

    -- combine successive commands
    flags = _combine_flags(flags, {"^%-gencode$", "^%-arch$", "^%-code$", "^%-%-machine$", "^%-rdc$", "^%-cudart$", "^%-%-keep%-dir$"})

    -- get flags string
    local flagstr = os.args(flags)

    if not (opt and opt.link) then

        -- make Optimization
        if flagstr:find("[%-/]Od") then
            vcxprojfile:print("<Optimization%s>Od</Optimization>", condition)
        elseif flagstr:find("[%-/]O1") then
            vcxprojfile:print("<Optimization%s>O1</Optimization>", condition)
        elseif flagstr:find("[%-/]O2") then
            vcxprojfile:print("<Optimization%s>O2</Optimization>", condition)
        elseif flagstr:find("[%-/]O3") or flagstr:find("[%-/]Ox") then
            vcxprojfile:print("<Optimization%s>O3</Optimization>", condition)
        end

        -- make Warning
        if flagstr:find("[%-/]W[1234]") then
            local wlevel = flagstr:match("[%-/](W[1234])")
            vcxprojfile:print("<Warning%s>%s</Warning>", condition, wlevel)
        elseif flagstr:find("[%-/]Wall") then
            vcxprojfile:print("<Warning%s>Wall</Warning>", condition)
        end

        -- make Defines
        local defstr = ""
        for _, flag in ipairs(flags) do
            flag:gsub("^[%-/]D(.*)",
                function (def)
                    defstr = defstr .. vsutils.escape(def) .. ";"
                end
            )
        end
        defstr = defstr .. "%%(Defines)"
        vcxprojfile:print("<Defines%s>%s</Defines>", condition, defstr)

        -- make Include
        if flagstr:find("[%-/]I") then
            local dirs = {}
            for _, flag in ipairs(flags) do
                flag:gsub("^[%-/]I(.*)", function (dir) table.insert(dirs, vsutils.escape(dir)) end)
            end
            if #dirs > 0 then
                vcxprojfile:print("<Include%s>%s</Include>", condition, table.concat(dirs, ";"))
            end
        end

    end

    -- make TargetMachinePlatform
    local machinebitwidth
    for _, flag in ipairs(flags) do
        flag:gsub("^%-m(.+)", function (value) machinebitwidth = value end)
        flag:gsub("^%-%-machine[ =](.+)", function (value) machinebitwidth = value end)
    end
    if machinebitwidth and (machinebitwidth == "32" or machinebitwidth == "64") then
        vcxprojfile:print("<TargetMachinePlatform%s>%s</TargetMachinePlatform>", condition, machinebitwidth)
    end

    -- make CodeGeneration
    local gpucode_patterns = {
        "%-gencode[ =]arch=(.+),code=(.+)",
        "%-%-generate%-code[ =]arch=(.+),code=(.+)",
        "%-arch",
        "%-%-gpu%-architecture",
        "%-code",
        "%-%-gpu%-code"
    }
    local has_gpucode = false
    for _, pattern in ipairs(gpucode_patterns) do
        if flagstr:find(pattern) then
            has_gpucode = true
            break
        end
    end
    if has_gpucode then
        local arch
        local codes = {}
        local gencodes = {}
        for _, flag in ipairs(flags) do
            flag:gsub("^%-gencode[ =]arch=(.+),code=(.+)$", function (garch, gcodes)
                for _, gcode in ipairs(_split_gpucodes(gcodes)) do
                    table.insert(gencodes, garch .. "," .. gcode)
                end
            end)
            flag:gsub("^%-%-generate%-code[ =]arch=(.+),code=(.+)", function (garch, gcodes)
                for _, gcode in ipairs(_split_gpucodes(gcodes)) do
                    table.insert(gencodes, garch .. "," .. gcode)
                end
            end)
            flag:gsub("^%-arch[ =](.+)", function (garch) arch = garch end)
            flag:gsub("^%-%-gpu%-architecture[ =](.+)", function (garch) arch = garch end)
            flag:gsub("^%-code[ =](.+)", function (gcodes) table.join2(codes, _split_gpucodes(gcodes)) end)
            flag:gsub("^%-%-gpu%-code[ =](.+)", function (gcodes) table.join2(codes, _split_gpucodes(gcodes)) end)
        end
        if arch then
            if #codes == 0 then
                table.insert(codes, arch)
                arch = arch:gsub("sm", "compute")
                table.insert(gencodes, arch .. "," .. arch)
            end
            for _, code in ipairs(codes) do
                table.insert(gencodes, arch .. "," .. code)
            end
        end
        if #gencodes > 0 then
            gencodes = table.unique(gencodes)
            vcxprojfile:print("<CodeGeneration%s>%s</CodeGeneration>", condition, table.concat(gencodes, ";"))
        end
    end

    if not (opt and opt.link) then

        -- make CudaRuntime
        local cudart
        local cudaruntime = {
            none = "None",
            static = "Static",
            shared = "Shared"
        }
        for _, flag in ipairs(flags) do
            flag:gsub("%-cudart[ =](.+)", function (value) cudart = value end)
        end
        if cudart and cudaruntime[cudart] then
            vcxprojfile:print("<CudaRuntime%s>%s</CudaRuntime>", condition, cudaruntime[cudart])
        end

        -- handle GPU debug info
        if flagstr:find("%-G") then
            vcxprojfile:print("<GPUDebugInfo%s>true</GPUDebugInfo>", condition)
        end

        -- handle fast math
        if flagstr:find("%-use_fast_math") then
            vcxprojfile:print("<FastMath%s>true</FastMath>", condition)
        end

        -- handle relocatable device code
        local rdc
        for _, flag in ipairs(flags) do
            flag:gsub("%-rdc[ =](.+)", function (value) rdc = value end)
        end
        if rdc then
            vcxprojfile:print("<GenerateRelocatableDeviceCode%s>%s</GenerateRelocatableDeviceCode>", condition, rdc)
        end

        -- handle keep preprocessed files or directories
        if flagstr:find("%-%-keep") then
            vcxprojfile:print("<Keep%s>true</Keep>", condition)
        end
        if flagstr:find("%-%-keep%-dir") then
            local dirs = {}
            for _, flag in ipairs(flags) do
                flag:gsub("%-%-keep%-dir[ =](.*)", function (dir) table.insert(dirs, dir) end)
            end
            if #dirs > 0 then
                vcxprojfile:print("<KeepDir%s>%s</KeepDir>", condition, table.concat(dirs, ";"))
            end
        end
    end

    -- make AdditionalOptions
    local excludes = {
        "Od", "O1", "O2", "O3", "Ox", "W1", "W2", "W3", "W4", "Wall", "I", "D", "L", "l", "m", "%-machine", "gencode", "arch", "code", "cudart", "G", "use_fast_math", "rdc", "%-keep", "%-keep%-dir"
    }
    local additional_flags = _exclude_flags(flags, excludes)
    if #additional_flags > 0 then
        vcxprojfile:print("<AdditionalOptions%s>%s %%(AdditionalOptions)</AdditionalOptions>", condition, os.args(additional_flags))
    end
end

-- make custom commands item
function _make_custom_commands_item(vcxprojfile, commands, suffix)
    if suffix == "after" or suffix == "after_link" then
        vcxprojfile:print("<PostBuildEvent>")
    elseif suffix == "before" then
        vcxprojfile:print("<PreBuildEvent>")
    elseif suffix == "before_link" then
        vcxprojfile:print("<PreLinkEvent>")
    end
    vcxprojfile:print("<Message></Message>")
    local cmdstr = "setlocal"
    for _, command in ipairs(commands) do
        cmdstr = cmdstr .. "\n" .. command
        cmdstr = cmdstr .. "\nif %errorlevel% neq 0 goto :xmEnd"
    end
    cmdstr = cmdstr .. "\n" .. [[:xmEnd
endlocal &amp; call :xmErrorLevel %errorlevel% &amp; goto :xmDone
:xmErrorLevel
exit /b %1
:xmDone
if %errorlevel% neq 0 goto :VCEnd]]
    vcxprojfile:print("<Command>%s</Command>", cmdstr:replace("<", " 	&lt;"):replace(">", "&gt;"):replace("/Fo ", "/Fo"))
    if suffix == "after" or suffix == "after_link" then
        vcxprojfile:print("</PostBuildEvent>")
    elseif suffix == "before" then
        vcxprojfile:print("</PreBuildEvent>")
    elseif suffix == "before_link" then
        vcxprojfile:print("</PreLinkEvent>")
    end
end

-- make custom commands
function _make_custom_commands(vcxprojfile, target)
    for suffix, cmds in pairs(target.commands) do
        _make_custom_commands_item(vcxprojfile, cmds, suffix)
    end
end

-- make common item
function _make_common_item(vcxprojfile, vsinfo, target, targetinfo)
    -- init the linker kinds
    local linkerkinds =
    {
        binary = "Link"
    ,   static = "Lib"
    ,   moduleonly = "Lib" -- emulate moduleonly with staticlib
    ,   shared = "Link"
    }
    if not linkerkinds[targetinfo.targetkind] then
        return
    end

    -- enter ItemDefinitionGroup
    vcxprojfile:enter("<ItemDefinitionGroup Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">", targetinfo.mode, targetinfo.arch)

    -- for linker?
    vcxprojfile:enter("<%s>", linkerkinds[targetinfo.targetkind])

        -- save subsystem
        local subsystem = "Console"

        -- save profile
        local profile = false

        -- make linker flags
        local flags = {}
        local excludes = {
            "nologo", "machine:%w+", "pdb:.+%.pdb", "debug"
        }
        local libdirs = {}
        local links = {}
        for _, flag in ipairs(_make_linkflags(targetinfo, target.project_dir)) do

            local flag_lower = flag:lower()

            -- remove "-subsystem:windows"
            if flag_lower:find("[%-/]subsystem:windows") then
                subsystem = "Windows"
            elseif flag_lower:find("[%-/]libpath") then
                -- link dir
                flag:gsub("[%-/]libpath:(.*)", function (dir) table.insert(libdirs, vsutils.escape(dir)) end)
            elseif flag_lower:find("[^%-/].+%.lib") then
                -- link file
                table.insert(links, flag)
            elseif flag_lower:find("[%-/]profile") then
                profile = true
            else
                local excluded = false
                for _, exclude in ipairs(excludes) do
                    if flag:find("[%-/]" .. exclude) then
                        excluded = true
                        break
                    end
                end
                if not excluded then
                    table.insert(flags, flag)
                end
            end

        end

        -- make AdditionalLibraryDirectories
        if #libdirs > 0 then
            vcxprojfile:print("<AdditionalLibraryDirectories>%s;%%(AdditionalLibraryDirectories)</AdditionalLibraryDirectories>", table.concat(libdirs, ";"))
        end

        -- make AdditionalDependencies
        if #links > 0 then
            vcxprojfile:print("<AdditionalDependencies>%s;%%(AdditionalDependencies)</AdditionalDependencies>", table.concat(links, ";"))
        end

        -- make AdditionalOptions
        if #flags > 0 then
            flags = os.args(flags)
            vcxprojfile:print("<AdditionalOptions>%s %%(AdditionalOptions)</AdditionalOptions>", vsutils.escape(flags))
        end

        -- generate debug infomation?
        if linkerkinds[targetinfo.targetkind] == "Link" then

            -- enable profile?
            vcxprojfile:print("<Profile>%s</Profile>", tostring(profile))

            -- enable debug infomation?
            local debug = false
            for _, symbol in ipairs(targetinfo.symbols) do
                if symbol == "debug" then
                    debug = true
                    break
                end
            end
            vcxprojfile:print("<GenerateDebugInformation>%s</GenerateDebugInformation>", tostring(debug))
        end

        -- make SubSystem
        if targetinfo.targetkind == "binary" then
            vcxprojfile:print("<SubSystem>%s</SubSystem>", subsystem)
        end

        -- make TargetMachine
        vcxprojfile:print("<TargetMachine>%s</TargetMachine>", (targetinfo.arch == "x64" and "MachineX64" or "MachineX86"))


    vcxprojfile:leave("</%s>", linkerkinds[targetinfo.targetkind])

    -- for C/C++ compiler?
    vcxprojfile:enter("<ClCompile>")

        -- make source options
        _make_source_options_cl(vcxprojfile, targetinfo.commonflags.cl)

        -- add c and c++ standard
        local clangflags = {
            c11       = "stdc11",
            c17       = "stdc17",
            clatest   = "stdc17",
            gnu11     = "stdc11",
            gnu17     = "stdc17",
            gnulatest = "stdc17",
        }

        local cxxlangflags = {
            cxx11     = "stdcpp11",
            cxx14     = "stdcpp14",
            cxx17     = "stdcpp17",
            cxx1z     = "stdcpp17",
            cxx20     = "stdcpp20",
            cxx2a     = "stdcpplatest",
            cxx23     = "stdcpplatest",
            cxx2b     = "stdcpplatest",
            cxxlatest = "stdcpplatest",
            gnuxx11   = "stdcpp11",
            gnuxx14   = "stdcpp14",
            gnuxx17   = "stdcpp17",
            gnuxx1z   = "stdcpp20",
            gnux20    = "stdcpp20",
            gnux2a    = "stdcpplatest",
        }

        local cstandard
        local cxxstandard
        for _, lang in pairs(targetinfo.languages) do
            lang = lang:replace("c++", "cxx", {plain = true})
            if cxxlangflags[lang] then
                cxxstandard = cxxlangflags[lang]
            elseif clangflags[lang] then
                cstandard = clangflags[lang]
            end
        end

        if cxxstandard then
            vcxprojfile:print("<LanguageStandard>%s</LanguageStandard>", cxxstandard)
        end

        if cstandard then
            vcxprojfile:print("<LanguageStandard_C>%s</LanguageStandard_C>", cstandard)
        end

        if targetinfo.has_modules then
            vcxprojfile:enter("<ScanSourceForModuleDependencies>true</ScanSourceForModuleDependencies>")
        end

        -- use c or c++ precompiled header
        local pcheader = target.pcxxheader or target.pcheader
        if pcheader then

            -- make precompiled header and outputfile
            vcxprojfile:print("<PrecompiledHeader>Use</PrecompiledHeader>")
            vcxprojfile:print("<PrecompiledHeaderFile>%s</PrecompiledHeaderFile>", vsutils.escape(path.filename(pcheader)))
            local pcoutputfile = targetinfo.pcxxoutputfile or targetinfo.pcoutputfile
            if pcoutputfile then
                vcxprojfile:print("<PrecompiledHeaderOutputFile>%s</PrecompiledHeaderOutputFile>", vsutils.escape(path.relative(path.absolute(pcoutputfile), target.project_dir)))
            end
            vcxprojfile:print("<ForcedIncludeFiles>%s;%%(ForcedIncludeFiles)</ForcedIncludeFiles>", vsutils.escape(path.filename(pcheader)))
        end

    vcxprojfile:leave("</ClCompile>")

    vcxprojfile:enter("<ResourceCompile>")
        -- make resource options
        _make_resource_options_cl(vcxprojfile, targetinfo.commonflags.cl)

    vcxprojfile:leave("</ResourceCompile>")

    local cuda = _check_cuda(target)
    if cuda then
        -- for CUDA linker?
        vcxprojfile:enter("<CudaLink>")

        -- make cuda link flags
        _make_source_options_cuda(vcxprojfile, targetinfo.culinkflags, {link = true})

        -- make devlink
        if targetinfo.cudevlink then
            vcxprojfile:print("<PerformDeviceLink>%s</PerformDeviceLink>", targetinfo.cudevlink)
        end

        vcxprojfile:leave("</CudaLink>")

        -- for CUDA compiler?
        vcxprojfile:enter("<CudaCompile>")

        -- make source options
        _make_source_options_cuda(vcxprojfile, targetinfo.commonflags.cuda)

        vcxprojfile:leave("</CudaCompile>")
    end

    -- make custom commands
    _make_custom_commands(vcxprojfile, targetinfo)

    -- leave ItemDefinitionGroup
    vcxprojfile:leave("</ItemDefinitionGroup>")
end

-- build common items (doesn't print anything)
function _build_common_items(vsinfo, target)

    -- for each mode and arch
    for _, targetinfo in ipairs(target.info) do

        -- make source flags
        local flags_stats = {cl = {}, cuda = {}}
        local files_count = {cl = 0, cuda = 0}
        local first_flags = {}
        targetinfo.sourceflags = {}
        for _, sourcebatch in pairs(targetinfo.sourcebatches) do
            local sourcekind = sourcebatch.sourcekind
            local rulename = sourcebatch.rulename
            if (rulename == "c.build" or rulename == "c++.build" or rulename == "c++.build.modules" or rulename == "asm.build" or sourcekind == "mrc") then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    -- make compiler flags
                    local flags = _make_compflags(sourcefile, targetinfo, target.project_dir)

                    -- no common flags for asm/rc
                    if sourcekind ~= "as" and sourcekind ~= "mrc" then
                        for _, flag in ipairs(table.unique(flags)) do
                            flags_stats.cl[flag] = (flags_stats.cl[flag] or 0) + 1
                        end

                        -- update files count
                        files_count.cl = files_count.cl + 1

                        -- save first flags
                        if first_flags.cl == nil then
                            first_flags.cl = flags
                        end
                    end

                    -- save source flags
                    targetinfo.sourceflags[sourcefile] = flags
                end
            elseif sourcekind == "cu" then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do

                    -- make compiler flags
                    local flags = _make_compflags(sourcefile, targetinfo, target.project_dir)

                    -- count flags
                    for _, flag in ipairs(table.unique(flags)) do
                        flags_stats.cuda[flag] = (flags_stats.cuda[flag] or 0) + 1
                    end

                    -- update files count
                    files_count.cuda = files_count.cuda + 1

                    -- save first flags
                    if first_flags.cuda == nil then
                        first_flags.cuda = flags
                    end

                    -- save source flags
                    targetinfo.sourceflags[sourcefile] = flags
                end
            end
        end

        -- make common flags
        targetinfo.commonflags = {cl = {}, cuda = {}}
        for _, comp in ipairs({"cl", "cuda"}) do
            for _, flag in ipairs(first_flags[comp]) do
                if flags_stats[comp][flag] >= files_count[comp] then
                    table.insert(targetinfo.commonflags[comp], flag)
                end
            end
        end

        -- remove common flags from source flags
        local sourceflags = {}
        for _, sourcebatch in pairs(targetinfo.sourcebatches) do
            local sourcekind = sourcebatch.sourcekind
            local rulename = sourcebatch.rulename
            if (sourcekind == "as" or sourcekind == "mrc") then
                -- no common flags for as/mrc files
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    sourceflags[sourcefile] = targetinfo.sourceflags[sourcefile]
                end
            elseif rulename == "c.build" or rulename == "c++.build" or rulename == "c++.build.modules" then -- sourcekind maybe bind multiple rules, e.g. c++modules
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    local flags = targetinfo.sourceflags[sourcefile]
                    local otherflags = {}
                    for _, flag in ipairs(flags) do
                        if flags_stats.cl[flag] < files_count.cl then
                            table.insert(otherflags, flag)
                        end
                    end
                    sourceflags[sourcefile] = otherflags
                end
            elseif sourcekind == "cu" then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    local flags = targetinfo.sourceflags[sourcefile]
                    local otherflags = {}
                    for _, flag in ipairs(flags) do
                        if flags_stats.cuda[flag] < files_count.cuda then
                            table.insert(otherflags, flag)
                        end
                    end
                    sourceflags[sourcefile] = otherflags
                end
            end
        end
        targetinfo.sourceflags = sourceflags
    end
end

-- make common items
function _make_common_items(vcxprojfile, vsinfo, target)

    -- for each mode and arch
    for _, targetinfo in ipairs(target.info) do
        -- make common item
        _make_common_item(vcxprojfile, vsinfo, target, targetinfo)
    end
end

-- make header file
function _make_include_file(vcxprojfile, includefile, vcxprojdir)
    vcxprojfile:print("<ClInclude Include=\"%s\" />", path.relative(path.absolute(includefile), vcxprojdir))
end

-- make source file for all modes
function _make_source_file_forall(vcxprojfile, vsinfo, target, sourcefile, sourceinfo)

    -- get object file and source kind
    local sourcekind
    for _, info in ipairs(sourceinfo) do
        sourcekind = info.sourcekind
        break
    end

    -- enter it
    local nodename
    if     sourcekind == "as"  then nodename = "CustomBuild"
    elseif sourcekind == "mrc" then nodename = "ResourceCompile"
    elseif sourcekind == "cu"  then nodename = "CudaCompile"
    elseif sourcekind == "cc" or sourcekind == "cxx" then nodename = "ClCompile"
    end
    sourcefile = path.relative(path.absolute(sourcefile), target.project_dir)
    vcxprojfile:enter("<%s Include=\"%s\">", nodename, sourcefile)

        -- for *.asm files
        if sourcekind == "as" then
            vcxprojfile:print("<ExcludedFromBuild>false</ExcludedFromBuild>")
            vcxprojfile:print("<FileType>Document</FileType>")
            for _, info in ipairs(sourceinfo) do
                local objectfile = path.relative(path.absolute(info.objectfile), target.project_dir)
                local compcmd = _make_compcmd(info.compargv, sourcefile, objectfile, target.project_dir)
                vcxprojfile:print("<Outputs Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s\'\">%s</Outputs>", info.mode .. '|' .. info.arch, objectfile)
                vcxprojfile:print("<Command Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s\'\">%s</Command>", info.mode .. '|' .. info.arch, compcmd)
            end
            vcxprojfile:print("<Message>%s</Message>", path.filename(sourcefile))

        -- for *.rc files
        elseif sourcekind == "mrc" then
            for _, info in ipairs(sourceinfo) do
                local objectfile = path.relative(path.absolute(info.objectfile), target.project_dir)
                vcxprojfile:print("<ResourceOutputFileName Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">%s</ResourceOutputFileName>",
                    info.mode, info.arch, objectfile)
            end

        -- for *.c/cpp/cu files
        else

            -- compile as c++ modules
            if _is_modulefile(sourcefile) then
                vcxprojfile:print("<CompileAs>CompileAsCppModule</CompileAs>")
            end

            -- we need to use different object directory and allow parallel building
            --
            -- @see https://github.com/xmake-io/xmake/issues/2016
            -- https://github.com/xmake-io/xmake/issues/1062
            for _, info in ipairs(sourceinfo) do
                local objectname = path.filename(info.objectfile)
                local targetinfo = info.targetinfo
                if not targetinfo.objectnames then
                    targetinfo.objectnames = hashset:new()
                end
                if targetinfo.objectnames:has(objectname) then
                    local outputnode = (sourcekind == "cu" and "CompileOut" or "ObjectFileName")
                    local objectfile = path.relative(path.absolute(info.objectfile), target.project_dir)
                    vcxprojfile:print("<%s Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">%s</%s>",
                        outputnode, info.mode, info.arch, objectfile, outputnode)
                else
                    targetinfo.objectnames:insert(objectname)
                end
            end

            -- init items
            local items =
            {
                AdditionalOptions =
                {
                    key = function (info) return os.args(info.flags) end
                ,   value = function (key) return key .. " %%(AdditionalOptions)" end
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
                    if sourcekind == "cu" or (pcheader and language.sourcekind_of(sourcefile) ~= (target.pcxxheader and "cxx" or "cc")) then
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
    vcxprojfile:leave("</%s>", nodename)
end

-- make source file for specific modes
function _make_source_file_forspec(vcxprojfile, vsinfo, target, sourcefile, sourceinfo)

    -- add source file
    sourcefile = path.relative(path.absolute(sourcefile), target.project_dir)
    for _, info in ipairs(sourceinfo) do

        -- enter it
        local nodename
        if     info.sourcekind == "as"  then nodename = "CustomBuild"
        elseif info.sourcekind == "mrc" then nodename = "ResourceCompile"
        elseif info.sourcekind == "cu"  then nodename = "CudaCompile"
        elseif info.sourcekind == "cc" or info.sourcekind == "cxx" then nodename = "ClCompile"
        end
        vcxprojfile:enter("<%s Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\" Include=\"%s\">",
            nodename, info.mode, info.arch, sourcefile)

        -- for *.asm files
        local objectfile = path.relative(path.absolute(info.objectfile), target.project_dir)
        if info.sourcekind == "as" then
            local compcmd = _make_compcmd(info.compargv, sourcefile, objectfile, target.project_dir)
            vcxprojfile:print("<ExcludedFromBuild>false</ExcludedFromBuild>")
            vcxprojfile:print("<FileType>Document</FileType>")
            vcxprojfile:print("<Outputs>%s</Outputs>", objectfile)
            vcxprojfile:print("<Command>%s</Command>", compcmd)

        -- for *.rc files
        elseif info.sourcekind == "mrc" then
            vcxprojfile:print("<ResourceOutputFileName Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">%s</ResourceOutputFileName>",
                info.mode, info.arch, objectfile)

        -- for *.c/cpp/cu files
        else
            -- compile as c++ modules
            if _is_modulefile(sourcefile) then
                vcxprojfile:print("<CompileAs>CompileAsCppModule</CompileAs>")
            end

           -- we need to use different object directory and allow parallel building
            --
            -- @see https://github.com/xmake-io/xmake/issues/2016
            -- https://github.com/xmake-io/xmake/issues/1062
            local objectname = path.filename(objectfile)
            local targetinfo = info.targetinfo
            if not targetinfo.objectnames then
                targetinfo.objectnames = hashset:new()
            end
            local targetinfo = info.targetinfo
            local outputnode = (info.sourcekind == "cu" and "CompileOut" or "ObjectFileName")
            if targetinfo.objectnames:has(objectname) then
                vcxprojfile:print("<%s Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">%s</%s>",
                    outputnode, info.mode, info.arch, objectfile, outputnode)
            else
                targetinfo.objectnames:insert(objectname)
            end

            -- disable the precompiled header if sourcekind ~= headerkind
            local pcheader = target.pcxxheader or target.pcheader
            if pcheader and info.sourcekind ~= "cu" and language.sourcekind_of(sourcefile) ~= (target.pcxxheader and "cxx" or "cc") then
                vcxprojfile:print("<PrecompiledHeader>NotUsing</PrecompiledHeader>")
            end
            vcxprojfile:print("<AdditionalOptions>%s %%(AdditionalOptions)</AdditionalOptions>", os.args(info.flags))
        end

        -- leave it
        vcxprojfile:leave("</%s>", nodename)
    end
end

-- make source file for precompiled header
function _make_source_file_forpch(vcxprojfile, vsinfo, target)

    -- add precompiled source file
    local pcheader = target.pcxxheader or target.pcheader
    if pcheader then
        local sourcefile = path.relative(path.absolute(pcheader), target.project_dir)
        vcxprojfile:enter("<ClCompile Include=\"%s\">", sourcefile)
            vcxprojfile:print("<PrecompiledHeader>Create</PrecompiledHeader>")
            vcxprojfile:print("<PrecompiledHeaderFile></PrecompiledHeaderFile>")
            vcxprojfile:print("<AdditionalOptions> %%(AdditionalOptions)</AdditionalOptions>")
            for _, info in ipairs(target.info) do

                -- compile as c/c++
                local compileas = (target.pcxxheader and "CompileAsCpp" or "CompileAsC")
                vcxprojfile:print("<CompileAs Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">%s</CompileAs>", info.mode, info.arch, compileas)

                -- add object file
                local pcoutputfile = info.pcxxoutputfile or info.pcoutputfile
                if pcoutputfile then
                    local objectfile = path.relative(path.absolute(pcoutputfile .. ".obj"), target.project_dir)
                    vcxprojfile:print("<ObjectFileName Condition=\"\'%$(Configuration)|%$(Platform)\'==\'%s|%s\'\">%s</ObjectFileName>", info.mode, info.arch, objectfile)
                end
            end
        vcxprojfile:leave("</ClCompile>")
    end
end

-- make source files
function _make_source_files(vcxprojfile, vsinfo, target)

    -- add source files
    vcxprojfile:enter("<ItemGroup>")

        -- make source file infos
        local sourceinfos = {}
        for _, targetinfo in ipairs(target.info) do
            for _, sourcebatch in pairs(targetinfo.sourcebatches) do
                local sourcekind = sourcebatch.sourcekind
                local rulename = sourcebatch.rulename
                if (rulename == "c.build" or rulename == "c++.build" or sourcekind == "as" or sourcekind == "mrc" or sourcekind == "cu") then
                    local objectfiles = sourcebatch.objectfiles
                    for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
                        local objectfile    = objectfiles[idx]
                        local flags         = targetinfo.sourceflags[sourcefile]
                        sourceinfos[sourcefile] = sourceinfos[sourcefile] or {}
                        table.insert(sourceinfos[sourcefile], {targetinfo = targetinfo, mode = targetinfo.mode, arch = targetinfo.arch, sourcekind = sourcekind, objectfile = objectfile, flags = flags, compargv = targetinfo.compargvs[sourcefile]})
                    end
                elseif rulename == "c++.build.modules" then
                    local builder_batch = targetinfo.sourcebatches["c++.build.modules.builder"]
                    table.sort(builder_batch.objectfiles)
                    local objectfiles = builder_batch.objectfiles
                    for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
                        local is_named_module = table.contains(builder_batch.sourcefiles, sourcefile)
                        if is_named_module then
                            local objectfile    = objectfiles[idx]
                            local flags         = targetinfo.sourceflags[sourcefile]
                            sourceinfos[sourcefile] = sourceinfos[sourcefile] or {}
                            table.insert(sourceinfos[sourcefile], {targetinfo = targetinfo, mode = targetinfo.mode, arch = targetinfo.arch, sourcekind = "cxx", objectfile = objectfile, flags = flags, compargv = targetinfo.compargvs[sourcefile]})
                        end
                    end
                end
            end
        end

        -- make source files
        for sourcefile, sourceinfo in table.orderpairs(sourceinfos) do
            if #sourceinfo == #target.info then
                _make_source_file_forall(vcxprojfile, vsinfo, target, sourcefile, sourceinfo)
            else
                _make_source_file_forspec(vcxprojfile, vsinfo, target, sourcefile, sourceinfo)
            end
        end

        -- make precompiled source file
        _make_source_file_forpch(vcxprojfile, vsinfo, target)

    vcxprojfile:leave("</ItemGroup>")

    -- add include files
    local pcheader = target.pcxxheader or target.pcheader
    vcxprojfile:enter("<ItemGroup>")
        for _, includefile in ipairs(table.join(target.headerfiles or {}, target.extrafiles)) do
            -- we need to ignore pcheader file to fix https://github.com/xmake-io/xmake/issues/1171
            if not pcheader or includefile ~= pcheader then
                _make_include_file(vcxprojfile, includefile, target.project_dir)
            end
        end
    vcxprojfile:leave("</ItemGroup>")
end

-- make vcxproj
function make(vsinfo, target)

    -- the target name
    local targetname = target.name

    -- the vcxproj directory
    local vcxprojdir = target.project_dir

    -- build common flags
    _build_common_items(vsinfo, target)

    -- open vcxproj file
    local vcxprojpath = path.join(vcxprojdir, targetname .. ".vcxproj")
    local vcxprojfile = vsfile.open(vcxprojpath, "w")

    -- init indent character
    vsfile.indentchar('  ')

    -- make header
    _make_header(vcxprojfile, vsinfo)

    -- make Configurations
    _make_configurations(vcxprojfile, vsinfo, target)

    -- make common items
    _make_common_items(vcxprojfile, vsinfo, target)

    -- make source files
    _make_source_files(vcxprojfile, vsinfo, target)

    -- make deps references
    _make_references(vcxprojfile, vsinfo, target)

    -- make tailer
    _make_tailer(vcxprojfile, vsinfo, target)

    -- exit solution file
    vcxprojfile:close()
end
