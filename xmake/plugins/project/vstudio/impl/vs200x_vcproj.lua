--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        vs200x_vcproj.lua
--

-- imports
import("core.tool.linker")
import("core.tool.archiver")
import("core.tool.compiler")
import("core.project.config")
import("vsfile")

-- make header
function _make_header(vcprojfile, vsinfo, target)

    -- the target name
    local targetname = target:name()

    -- the versions
    local versions = 
    {
        vs2002 = '7.0'
    ,   vs2003 = '7.1'
    ,   vs2005 = '8.0'
    ,   vs2008 = '9.0'
    }

    -- make header
    vcprojfile:print("<?xml version=\"1.0\" encoding=\"gb2312\"?>")
    vcprojfile:enter("<VisualStudioProject")
        vcprojfile:print("ProjectType=\"Visual C++\"")
        vcprojfile:print("Version=\"%s0\"", assert(versions["vs" .. vsinfo.vstudio_version]))
        vcprojfile:print("Name=\"%s\"", targetname)
        vcprojfile:print("ProjectGUID=\"{%s}\"", os.uuid(targetname))
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
-- .e.g
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
function _make_VCCLCompilerTool(vcprojfile, vsinfo, target)
    vcprojfile:enter("<Tool")
        vcprojfile:print("Name=\"VCCLCompilerTool\"")
    vcprojfile:leave("/>")
end

-- make VCLinkerTool
--
-- .e.g
-- <Tool
--      Name="VCLinkerTool"
--      AdditionalDependencies="xxx.lib"
--      LinkIncremental="2"
--      AdditionalLibraryDirectories="&quot;$(SolutionDir)\..\..\lib&quot;"
--      GenerateDebugInformation="true"
--      SubSystem="1"
--      TargetMachine="1"
-- />
function _make_VCLinkerTool(vcprojfile, vsinfo, target)

    -- need not linker?
    local kind = target:get("kind")
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

    -- make it
    vcprojfile:enter("<Tool")
        vcprojfile:print("Name=\"VCLinkerTool\"")
        vcprojfile:print("AdditionalOptions=\"%s\"", linker.linkflags(target))
		vcprojfile:print("AdditionalDependencies=\"\"")
		vcprojfile:print("AdditionalLibraryDirectories=\"\"")
        vcprojfile:print("LinkIncremental=\"2\"") -- enable: 2, disable: 1
        vcprojfile:print("GenerateDebugInformation=\"%s\"", tostring(debug))
        vcprojfile:print("SubSystem=\"1\"") -- console: 1, windows: 2
        vcprojfile:print("TargetMachine=\"%d\"", ifelse(config.arch() == "x64", 17, 1))
    vcprojfile:leave("/>")
end

-- make configurations
function _make_configurations(vcprojfile, vsinfo, target)

    -- init configuration type
    local configuration_types =
    {
        binary = 1
    ,   shared = 2
    ,   static = 4
    }
 
    -- enter configurations
    vcprojfile:enter("<Configurations>")

        -- make configuration for the current mode
        vcprojfile:enter("<Configuration")
            vcprojfile:print("Name=\"$(mode)|Win32\"")
			vcprojfile:print("OutputDirectory=\"$(buildir)\\%s\"", target:name())
			vcprojfile:print("IntermediateDirectory=\"%$(ConfigurationName)\"")
			vcprojfile:print("ConfigurationType=\"%d\"", assert(configuration_types[target:get("kind")]))
            vcprojfile:print("CharacterSet=\"2\"") -- mbc: 2, wcs: 1
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
            _make_VCCLCompilerTool(vcprojfile, vsinfo, target)

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
            _make_VCLinkerTool(vcprojfile, vsinfo, target)

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

-- make files
function _make_files(vcprojfile, vsinfo, target)
 
    vcprojfile:enter("<Files>")
	vcprojfile:leave("</Files>")
end

-- make globals
function _make_globals(vcprojfile, vsinfo, target)
 
    vcprojfile:enter("<Globals>")
	vcprojfile:leave("</Globals>")
end

-- make vcproj
function make(outputdir, vsinfo, target)

    -- the target name
    local targetname = target:name()

    -- open vcproj file
    local vcprojfile = vsfile.open(format("%s/vs%s/%s/%s.vcproj", outputdir, vsinfo.vstudio_version, targetname, targetname), "w")

    -- make header
    _make_header(vcprojfile, vsinfo, target)

    -- make platforms
    _make_platforms(vcprojfile, vsinfo, target)

    -- make toolfiles
    _make_toolfiles(vcprojfile, vsinfo, target)

    -- make configurations
    _make_configurations(vcprojfile, vsinfo, target)

    -- make references
    _make_references(vcprojfile, vsinfo, target)

    -- make files
    _make_files(vcprojfile, vsinfo, target)

    -- make globals
    _make_globals(vcprojfile, vsinfo, target)

    -- make tailer
    _make_tailer(vcprojfile, vsinfo, target)

    -- exit solution file
    vcprojfile:close()
end
