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
-- @file        vs200x_vcproj.lua
--

-- imports
import("core.tool.linker")
import("core.tool.compiler")
import("core.project.config")
import("vsfile")

-- make compiling flags
function _make_compflags(sourcefile, target, vcprojdir)

    -- make the compiling flags
    local compflags = compiler.compflags(sourcefile, {target = target})

    -- replace -Idir or /Idir, -Fdsymbol.pdb or /Fdsymbol.pdb
    local flags = {}
    for _, flag in ipairs(compflags) do

        -- replace -Idir or /Idir
        flag = flag:gsub("[%-|/]I(.*)", function (dir)
                        dir = path.translate(dir:trim())
                        if not path.is_absolute(dir) then
                            dir = path.relative(path.absolute(dir), vcprojdir)
                        end
                        return "/I" .. dir
                    end)

        -- replace -Fdsymbol.pdb or /Fdsymbol.pdb
        flag = flag:gsub("[%-|/]Fd(.*)", function (dir)
                        dir = path.translate(dir:trim())
                        if not path.is_absolute(dir) then
                            dir = path.relative(path.absolute(dir), vcprojdir)
                        end
                        return "/Fd" .. dir
                    end)

        -- save flag
        table.insert(flags, flag)
    end

    -- make flags string
    flags = os.args(flags)

    -- replace " => &quot;
    flags = flags:gsub("\"", "&quot;")

    -- ok?
    return flags
end

-- make linking flags
function _make_linkflags(target, vcprojdir)

    -- make the linking flags
    local linkflags = linker.linkflags(target:targetkind(), target:sourcekinds(), {target = target})

    -- replace -libpath:dir or /libpath:dir, -pdb:symbol.pdb or /pdb:symbol.pdb
    local flags = {}
    for _, flag in ipairs(linkflags) do

        -- replace -libpath:dir or /libpath:dir
        flag = flag:gsub("[%-|/]libpath:(.*)", function (dir)
                        dir = path.translate(dir:trim())
                        if not path.is_absolute(dir) then
                            dir = path.relative(path.absolute(dir), vcprojdir)
                        end
                        return "/libpath:" .. dir
                    end)

        -- replace -pdb:symbol.pdb or /pdb:symbol.pdb
        flag = flag:gsub("[%-|/]pdb:(.*)", function (dir)
                        dir = path.translate(dir:trim())
                        if not path.is_absolute(dir) then
                            dir = path.relative(path.absolute(dir), vcprojdir)
                        end
                        return "/pdb:" .. dir
                    end)

        -- save flag
        table.insert(flags, flag)
    end

    -- make flags string
    flags = os.args(flags)

    -- replace " => &quot;
    flags = flags:gsub("\"", "&quot;")

    -- ok?
    return flags
end

-- make header
function _make_header(vcprojfile, vsinfo, target)

    -- the target name
    local targetname = target:name()

    -- make header
    vcprojfile:print("<?xml version=\"1.0\" encoding=\"utf-8\"?>")
    vcprojfile:enter("<VisualStudioProject")
        vcprojfile:print("ProjectType=\"Visual C++\"")
        vcprojfile:print("Version=\"%s0\"", assert(vsinfo.project_version))
        vcprojfile:print("Name=\"%s\"", targetname)
        vcprojfile:print("ProjectGUID=\"{%s}\"", hash.uuid4(targetname))
        vcprojfile:print("RootNamespace=\"%s\"", targetname)
        vcprojfile:print("TargetFrameworkVersion=\"196613\"")
        vcprojfile:print(">")
end

-- make tailer
function _make_tailer(vcprojfile, vsinfo, target)
    vcprojfile:leave("</VisualStudioProject>")
end

-- make platforms
function _make_platforms(vcprojfile, vsinfo, target)

    -- add Win32 platform
    vcprojfile:enter("<Platforms>")
		vcprojfile:enter("<Platform")
			vcprojfile:print("Name=\"Win32\"")
		vcprojfile:leave("/>")
	vcprojfile:leave("</Platforms>")
end

-- make toolfiles
function _make_toolfiles(vcprojfile, vsinfo, target)

    -- empty toolfiles
    vcprojfile:enter("<ToolFiles>")
	vcprojfile:leave("</ToolFiles>")
end

-- make VCCLCompilerTool
--
-- e.g.
--
-- <Tool
--      Name="VCCLCompilerTool"
--      AdditionalOptions="/TP"
--      Optimization="0"
--      AdditionalIncludeDirectories="&quot;$(SolutionDir)\..\..\src&quot;;&quot;"
--      PreprocessorDefinitions=""
--      MinimalRebuild="true"
--      BasicRuntimeChecks="3"
--      RuntimeLibrary="3"
--      UsePrecompiledHeader="0"
--      WarningLevel="3"
--      DebugInformationFormat="4"
-- />
function _make_VCCLCompilerTool(vcprojfile, vsinfo, target, compflags)
    vcprojfile:enter("<Tool")
        vcprojfile:print("Name=\"VCCLCompilerTool\"")
        vcprojfile:print("ProgramDataBaseFileName=\"\"") -- disable pdb file default
        -- MT:0, MTd:1, MD:2, MDd:3, ML:4, MLd:5
        local runtime = 0
        for _,flag in pairs(compflags) do
            if flag:find("[%-|/]MD") then
                runtime = 2
                break
            elseif flag:find("[%-|/]MT") then
                runtime = 0
                break
            end
        end
        vcprojfile:print("RuntimeLibrary=\"%d\"", is_mode("debug") and runtime + 1 or runtime)
    vcprojfile:leave("/>")
end

-- make VCLinkerTool
--
-- e.g.
-- <Tool
--      Name="VCLinkerTool"
--      AdditionalDependencies="xxx.lib"
--      LinkIncremental="2"
--      AdditionalLibraryDirectories="&quot;$(SolutionDir)\..\..\lib&quot;"
--      GenerateDebugInformation="true"
--      SubSystem="1"
--      TargetMachine="1"
-- />
function _make_VCLinkerTool(vcprojfile, vsinfo, target, vcprojdir)

    -- need not linker?
    local kind = target:targetkind()
    if kind ~= "binary" and kind ~= "shared" then
        vcprojfile:enter("<Tool")
            vcprojfile:print("Name=\"VCLinkerTool\"")
        vcprojfile:leave("/>")
        return
    end

    -- generate debug infomation?
    local debug = false
    for _, symbol in ipairs(target:get("symbols")) do
        if symbol == "debug" then
            debug = true
            break
        end
    end

    -- subsystem, console: 1, windows: 2
    local subsystem = 1
    local flags = _make_linkflags(target, vcprojdir)
    if flags:lower():find("[%-/]subsystem:windows") then
        subsystem = 2
    end

    -- make it
    vcprojfile:enter("<Tool")
        vcprojfile:print("Name=\"VCLinkerTool\"")
        vcprojfile:print("AdditionalOptions=\"%s\"", flags)
		vcprojfile:print("AdditionalDependencies=\"\"")
		vcprojfile:print("AdditionalLibraryDirectories=\"\"")
        vcprojfile:print("LinkIncremental=\"2\"") -- enable: 2, disable: 1
        vcprojfile:print("GenerateDebugInformation=\"%s\"", tostring(debug))
        vcprojfile:print("SubSystem=\"%d\"", subsystem) -- console: 1, windows: 2
        vcprojfile:print("TargetMachine=\"%d\"", is_arch("x64") and 17 or 1)
    vcprojfile:leave("/>")
end

-- make configurations
function _make_configurations(vcprojfile, vsinfo, target, vcprojdir)

    -- init configuration type
    local configuration_types =
    {
        binary = 1
    ,   shared = 2
    ,   static = 4
    }

    -- save compiler flags
    local compflags=nil
    for _, sourcebatch in pairs(target:sourcebatches()) do
        local sourcekind = sourcebatch.sourcekind
        if sourcekind then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local flags = compiler.compflags(sourcefile, {target = target})
                if sourcekind == "cc" or sourcekind == "cxx" then
                    compflags = flags
                    break
                end
            end
        end
        if compflags then
            break
        end
    end

    -- use mfc? not used: 0, static: 1, shared: 2
    local usemfc = 0
    if target:rule("win.sdk.mfc.shared_app") or target:rule("win.sdk.mfc.shared") then
        usemfc = 2
    elseif target:rule("win.sdk.mfc.static_app") or target:rule("win.sdk.mfc.static") then
        usemfc = 1
    end

    -- set unicode
    local unicode = false
    for _, flag in ipairs(compflags) do
        if flag:find("[%-|/]DUNICODE") then
            unicode = true
            break
        end
    end

    -- enter configurations
    vcprojfile:enter("<Configurations>")

        -- make configuration for the current mode
        vcprojfile:enter("<Configuration")
            vcprojfile:print("Name=\"$(mode)|Win32\"")
			vcprojfile:print("OutputDirectory=\"%s\"", path.relative(path.absolute(target:targetdir()), vcprojdir))
			vcprojfile:print("IntermediateDirectory=\"%s\"", path.relative(path.absolute(target:objectdir()), vcprojdir))
			vcprojfile:print("ConfigurationType=\"%d\"", assert(configuration_types[target:targetkind()]))
            vcprojfile:print("CharacterSet=\"%d\"", unicode and 1 or 2) -- mbc: 2, wcs: 1
            vcprojfile:print("UseOfMFC=\"%d\"", usemfc)
            vcprojfile:print(">")

            -- make VCPreBuildEventTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCPreBuildEventTool\"")
            vcprojfile:leave("/>")

            -- make VCCustomBuildTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCCustomBuildTool\"")
            vcprojfile:leave("/>")

            -- make VCXMLDataGeneratorTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCXMLDataGeneratorTool\"")
            vcprojfile:leave("/>")

            -- make VCWebServiceProxyGeneratorTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCWebServiceProxyGeneratorTool\"")
            vcprojfile:leave("/>")

            -- make VCMIDLTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCMIDLTool\"")
            vcprojfile:leave("/>")

            -- make VCCLCompilerTool
            _make_VCCLCompilerTool(vcprojfile, vsinfo, target, compflags)

            -- make VCManagedResourceCompilerTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCManagedResourceCompilerTool\"")
            vcprojfile:leave("/>")

            -- make VCResourceCompilerTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCResourceCompilerTool\"")
            vcprojfile:leave("/>")

            -- make VCPreLinkEventTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCPreLinkEventTool\"")
            vcprojfile:leave("/>")

            -- make VCLinkerTool
            _make_VCLinkerTool(vcprojfile, vsinfo, target, vcprojdir)

            -- make VCALinkTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCALinkTool\"")
            vcprojfile:leave("/>")

            -- make VCManifestTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCManifestTool\"")
            vcprojfile:leave("/>")

            -- make VCXDCMakeTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCXDCMakeTool\"")
            vcprojfile:leave("/>")

            -- make VCBscMakeTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCBscMakeTool\"")
            vcprojfile:leave("/>")

            -- make VCFxCopTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCFxCopTool\"")
            vcprojfile:leave("/>")

            -- make VCAppVerifierTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCAppVerifierTool\"")
            vcprojfile:leave("/>")

            -- make VCPostBuildEventTool
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCPostBuildEventTool\"")
            vcprojfile:leave("/>")


        -- leave configuration
        vcprojfile:leave("</Configuration>")

    -- leave configurations
	vcprojfile:leave("</Configurations>")
end

-- make references
function _make_references(vcprojfile, vsinfo, target)
    vcprojfile:enter("<References>")
	vcprojfile:leave("</References>")
end

-- make cxfile
--
-- e.g.
--  <File
--      RelativePath="..\..\..\src\file3.c"
--      >
--      <FileConfiguration
--          Name="Debug|Win32"
--          >
--          <Tool
--              Name="VCCLCompilerTool"
--              AdditionalOptions="-Dtest"
--          />
--      </FileConfiguration>
--  </File>
function _make_cxfile(vcprojfile, vsinfo, target, sourcefile, objectfile, vcprojdir)

    -- get the target key
    local key = target:cachekey()

    -- make flags cache
    _g.flags = _g.flags or {}

    -- make flags
    local flags = _g.flags[key] or _make_compflags(sourcefile, target, vcprojdir)
    _g.flags[key] = flags

    -- enter file
    vcprojfile:enter("<File")

        -- add file path
        vcprojfile:print("RelativePath=\"%s\"", path.relative(path.absolute(sourcefile), vcprojdir))
        vcprojfile:print(">")

        -- add file configuration
        vcprojfile:enter("<FileConfiguration")
            vcprojfile:print("Name=\"$(mode)|Win32\"")
            vcprojfile:print(">")

            -- add compiling options
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCCLCompilerTool\"")
                vcprojfile:print("AdditionalOptions=\"%s\"", flags)
                vcprojfile:print("ObjectFile=\"%s\"", path.relative(path.absolute(objectfile), vcprojdir))

                -- compile as c++ if exists flag: /TP
                if flags:find("[%-|/]TP") then
                    vcprojfile:print("CompileAs=\"2\"")
                end
            vcprojfile:leave("/>")
        vcprojfile:leave("</FileConfiguration>")

    -- leave file
    vcprojfile:leave("</File>")
end

-- make rcfile
--
-- e.g.
--  <File
--      RelativePath="..\..\..\src\resource.rc"
--      >
--      <FileConfiguration
--          Name="Debug|Win32"
--          >
--          <Tool
--              Name="VCResourceCompilerTool"
--              ResourceOutputFileName="..\..\..\build\src\resource.res"
--          />
--      </FileConfiguration>
--  </File>
function _make_rcfile(vcprojfile, vsinfo, target, sourcefile, objectfile, vcprojdir)

    -- enter file
    vcprojfile:enter("<File")

        -- add file path
        vcprojfile:print("RelativePath=\"%s\"", path.relative(path.absolute(sourcefile), vcprojdir))
        vcprojfile:print(">")

        -- add file configuration
        vcprojfile:enter("<FileConfiguration")
            vcprojfile:print("Name=\"$(mode)|Win32\"")
            vcprojfile:print(">")

            -- add compiling options
            vcprojfile:enter("<Tool")
                vcprojfile:print("Name=\"VCResourceCompilerTool\"")
                -- FIXME: multi rc files support
                -- vcprojfile:print("ResourceOutputFileName=\"%s\"", path.relative(path.absolute(objectfile), vcprojdir))
            vcprojfile:leave("/>")
        vcprojfile:leave("</FileConfiguration>")

    -- leave file
    vcprojfile:leave("</File>")
end

-- make files
--
-- e.g.
-- <Filter
--      Name="Source Files"
--      >
--      <File
--          RelativePath="..\..\..\src\file1.c"
--          >
--      </File>
--      <File
--          RelativePath="..\..\..\src\file2.c"
--          >
--      </File>
--      <File
--          RelativePath="..\..\..\src\file3.c"
--          >
--          <FileConfiguration
--              Name="Debug|Win32"
--              >
--              <Tool
--                  Name="VCCLCompilerTool"
--                  AdditionalOptions="-Dtest"
--              />
--          </FileConfiguration>
--      </File>
--      <File
--          RelativePath="..\..\..\src\file4.c"
--          >
--      </File>
-- </Filter>
function _make_files(vcprojfile, vsinfo, target, vcprojdir)

    -- enter files
    vcprojfile:enter("<Files>")
        local sourcebatches = target:sourcebatches()
        -- c/cxx files
        vcprojfile:enter("<Filter Name=\"Source Files\">")
            for _, sourcebatch in pairs(sourcebatches) do
                local sourcekind = sourcebatch.sourcekind
                if sourcekind ~= "mrc" then
                    local objectfiles = sourcebatch.objectfiles
                    for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
                        _make_cxfile(vcprojfile, vsinfo, target, sourcefile, objectfiles[idx], vcprojdir)
                    end
                end
            end

        -- leave c/cxx files
        vcprojfile:leave("</Filter>")

        -- *.rc files
        vcprojfile:enter("<Filter Name=\"Resource Files\">")
            for _, sourcebatch in pairs(sourcebatches) do
                local sourcekind = sourcebatch.sourcekind
                if sourcekind == "mrc" then
                    local objectfiles = sourcebatch.objectfiles
                    for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
                        _make_rcfile(vcprojfile, vsinfo, target, sourcefile, objectfiles[idx], vcprojdir)
                    end
                end
            end

        -- leave *.rc files
        vcprojfile:leave("</Filter>")

	vcprojfile:leave("</Files>")
end

-- make globals
function _make_globals(vcprojfile, vsinfo, target)
    vcprojfile:enter("<Globals>")
	vcprojfile:leave("</Globals>")
end

-- make vcproj
function make(vsinfo, target)

    -- the target name
    local targetname = target:name()

    -- the vcproj directory
    local vcprojdir = path.join(vsinfo.solution_dir, targetname)

    -- open vcproj file
    local vcprojfile = vsfile.open(path.join(vcprojdir, targetname .. ".vcproj"), "w")

    -- init indent character
    vsfile.indentchar('\t')

    -- make header
    _make_header(vcprojfile, vsinfo, target)

    -- make platforms
    _make_platforms(vcprojfile, vsinfo, target)

    -- make toolfiles
    _make_toolfiles(vcprojfile, vsinfo, target)

    -- make configurations
    _make_configurations(vcprojfile, vsinfo, target, vcprojdir)

    -- make references
    _make_references(vcprojfile, vsinfo, target)

    -- make files
    _make_files(vcprojfile, vsinfo, target, vcprojdir)

    -- make globals
    _make_globals(vcprojfile, vsinfo, target)

    -- make tailer
    _make_tailer(vcprojfile, vsinfo, target)

    -- exit solution file
    vcprojfile:close()
end
