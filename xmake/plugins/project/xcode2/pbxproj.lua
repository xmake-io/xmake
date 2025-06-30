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
-- @author      JXMaster
-- @file        pbxproj.lua
--

-- imports
import("core.project.config")
import("core.project.project")

function _write_file_if_needed(file, content)
    if os.isfile(file) and io.readfile(file) == content then
        dprint("skipped file %s since the file has the same content", path.relative(file))
        return
    end
    -- we need utf8 with bom encoding for unicode
    -- @see https://github.com/xmake-io/xmake/issues/1689
    io.writefile(file, content, {encoding = "utf8"})
end

function _write_section_PBXFileReference(info, lines)
    table.insert(lines, "/* Begin PBXFileReference section */")
    for uuid, obj in table.orderpairs(info.sections.PBXFileReference) do
        table.insert(lines, "\t\t" .. uuid .. " = {")
        table.insert(lines, "\t\t\tisa = PBXFileReference;")
        if obj.explicitFileType then
            table.insert(lines, "\t\t\texplicitFileType = \"" .. obj.explicitFileType .. "\";")
        end
        if obj.lastKnownFileType then
            table.insert(lines, "\t\t\tlastKnownFileType = \"" .. obj.lastKnownFileType .. "\";")
        end
        if obj.includeInIndex then
            table.insert(lines, "\t\t\tincludeInIndex = " .. obj.includeInIndex .. ";")
        end
        if obj.name then
            table.insert(lines, "\t\t\tname = \"" .. obj.name .. "\";")
        end
        if obj.path then
            table.insert(lines, "\t\t\tpath = \"" .. obj.path .. "\";")
        end
        if obj.sourceTree then
            table.insert(lines, "\t\t\tsourceTree = " .. obj.sourceTree .. ";")
        end
        table.insert(lines, "\t\t};")
    end
    table.insert(lines, "/* End PBXFileReference section */")
end

function _write_section_PBXGroup(info, lines)
    table.insert(lines, "/* Begin PBXGroup section */")
    for uuid, obj in table.orderpairs(info.sections.PBXGroup) do
        table.insert(lines, "\t\t" .. uuid .. " = {")
        table.insert(lines, "\t\t\tisa = PBXGroup;")
        if obj.name then
            table.insert(lines, "\t\t\tname = \"" .. obj.name .. "\";")
        end
        table.insert(lines, "\t\t\tchildren = (")
        for _, child in ipairs(obj.children) do
            local child_obj = info.sections.PBXFileReference[child]
            if child_obj == nil then
                child_obj = info.sections.PBXGroup[child]
            end
            local child_name
            if child_obj then
                child_name = child_obj.name
            end
            if child_name == nil then
                child_name = ""
            end
            table.insert(lines, "\t\t\t\t" .. child .. " /* " .. child_name .. " */,")
        end
        table.insert(lines, "\t\t\t);")
        table.insert(lines, "\t\t\tsourceTree = \"" .. obj.sourceTree .. "\";")
        table.insert(lines, "\t\t};")
    end
    table.insert(lines, "/* End PBXGroup section */")
end

function _write_section_PBXNativeTarget(info, lines)
    table.insert(lines, "/* Begin PBXNativeTarget section */")
    for uuid, obj in table.orderpairs(info.sections.PBXNativeTarget) do
        table.insert(lines, "\t\t" .. uuid .. " /* " .. obj.name .. " */ = {")
        table.insert(lines, "\t\t\tisa = PBXNativeTarget;")
        table.insert(lines, "\t\t\tbuildConfigurationList = " .. obj.buildConfigurationList .. " /* Build configuration list for PBXNativeTarget \"" .. obj.name .. "\" */;")
        table.insert(lines, "\t\t\tbuildPhases = (")
        for _, build_phase_uuid in ipairs(obj.buildPhases) do
            table.insert(lines, "\t\t\t\t" .. build_phase_uuid .. ",")
        end
        table.insert(lines, "\t\t\t);")
        table.insert(lines, "\t\t\tbuildRules = (")
        table.insert(lines, "\t\t\t);")
        table.insert(lines, "\t\t\tdependencies = (")
        table.insert(lines, "\t\t\t);")
        table.insert(lines, "\t\t\tname = " .. obj.name .. ";")
        table.insert(lines, "\t\t\tpackageProductDependencies = (")
        table.insert(lines, "\t\t\t);")
        table.insert(lines, "\t\t\tproductName = " .. obj.productName .. ";")
        local product_reference_name
        local product_reference_obj = info.sections.PBXFileReference[obj.productReference]
        if product_reference_obj then
            product_reference_name = product_reference_obj.name
        end
        if product_reference_name == nil then
            product_reference_name = ""
        end
        table.insert(lines, "\t\t\tproductReference = " .. obj.productReference .. " /* " .. product_reference_name .. " */;")
        table.insert(lines, "\t\t\tproductType = " .. obj.productType .. ";")
        table.insert(lines, "\t\t};")
    end
    table.insert(lines, "/* End PBXNativeTarget section */")
end

function _write_section_PBXProject(info, lines)
    table.insert(lines, "/* Begin PBXProject section */")
    for uuid, obj in table.orderpairs(info.sections.PBXProject) do
        table.insert(lines, "\t\t" .. uuid .. " /* Project object */ = {")
        table.insert(lines, "\t\t\tisa = PBXProject;")
        table.insert(lines, [[
			attributes = {
				BuildIndependentTargetsInParallel = 1;
			};]])
        table.insert(lines, "\t\t\tbuildConfigurationList = " .. obj.buildConfigurationList .. " /* Build configuration list for PBXProject */;")
        table.insert(lines, [[
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);]])
        table.insert(lines, "mainGroup = " .. obj.mainGroup .. ";")
        table.insert(lines, [[
			minimizedProjectReferenceProxies = 1;
			preferredProjectObjectVersion = 77;]])
        table.insert(lines, "productRefGroup = " .. obj.productRefGroup .. ";")
        table.insert(lines, [[
			projectDirPath = "";
			projectRoot = "";]])
        table.insert(lines, "\t\t\ttargets = (")
        for _, target_uuid in ipairs(obj.targets) do
            table.insert(lines, "\t\t\t\t" .. target_uuid .. " /* " .. info.sections.PBXNativeTarget[target_uuid].name .. " */,")
        end
        table.insert(lines, "\t\t\t);")
        table.insert(lines, "\t\t};")
    end
    table.insert(lines, "/* End PBXProject section */")
end

function _write_section_PBXShellScriptBuildPhase(info, lines)
    table.insert(lines, "/* Begin PBXShellScriptBuildPhase section */")
    for uuid, obj in table.orderpairs(info.sections.PBXShellScriptBuildPhase) do
        table.insert(lines, "\t\t" .. uuid .. " /* Run xmake Build Command */ = {")
        table.insert(lines, [[
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputFileListPaths = (
			);
			inputPaths = (
			);
			name = "xmake build";
			outputFileListPaths = (
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "]] .. obj.shellScript .. "\";")
        table.insert(lines, "\t\t};")
    end
    table.insert(lines, "/* End PBXShellScriptBuildPhase section */")
end

function _write_section_XCBuildConfiguration(info, lines)
    table.insert(lines, "/* Begin XCBuildConfiguration section */")
    for uuid, obj in table.orderpairs(info.sections.XCBuildConfiguration) do
        table.insert(lines, "\t\t" .. uuid .. " /* " .. obj.name .. " */ = {")
        table.insert(lines, [[
			isa = XCBuildConfiguration;
			buildSettings = {]])
        for k, v in pairs(obj.buildSettings) do
            local string_value = ""
            if v == true then
                string_value = "YES"
            elseif v == false then
                string_value = "NO"
            elseif type(v) == "string" then
                string_value = v
            elseif type(v) == "number" then
                string_value = tostring(v)
            end
            table.insert(lines, "\t\t\t\t" .. k .. " = " .. string_value .. ";")
        end
		table.insert(lines, [[
            };
			name = ]] .. obj.name .. ";")
        table.insert(lines, "\t\t};")
    end
    table.insert(lines, "/* End XCBuildConfiguration section */")
end

function _write_section_XCConfigurationList(info, lines)
    table.insert(lines, "/* Begin XCConfigurationList section */")
    for uuid, obj in table.orderpairs(info.sections.XCConfigurationList) do
        table.insert(lines, "\t\t" .. uuid .. " = {")
        table.insert(lines, [[
			isa = XCConfigurationList;
			buildConfigurations = (]])
        for _, build_config in ipairs(obj.buildConfigurations) do
            table.insert(lines, "\t\t\t\t" .. build_config .. " /* " .. info.sections.XCBuildConfiguration[build_config].name .. " */,")
        end
        table.insert(lines, [[
			);
			defaultConfigurationIsVisible = 0;]])
        table.insert(lines, "\t\t};")
    end
    table.insert(lines, "/* End XCConfigurationList section */")
end

local write_section_funcs = {
    _write_section_PBXFileReference,
    _write_section_PBXGroup,
    _write_section_PBXNativeTarget,
    _write_section_PBXProject,
    _write_section_PBXShellScriptBuildPhase,
    _write_section_XCBuildConfiguration,
    _write_section_XCConfigurationList
}

function _write_pbxproj(info)
    local lines = {}
    table.insert(lines, [[// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 77;
	objects = {
]])
    -- write sections.
    for _, write_section in ipairs(write_section_funcs) do
        write_section(info, lines)
    end

    table.insert(lines, 
[[	};
	rootObject = ]] .. info.root_object .. [[ /* Project object */;
}]])
    return table.concat(lines, "\n") .. "\n"
end

function main(info)
    local content = _write_pbxproj(info)
    local file_name = path.join(info.project_dir, info.project_bundle, "project.pbxproj")
    _write_file_if_needed(file_name, content)
end