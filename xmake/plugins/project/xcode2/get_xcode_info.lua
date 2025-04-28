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
-- @file        get_xcode_info.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")

function _get_project_modes()
    local ret_modes = {}
    local modes = option.get("modes")
    if modes then
        if not modes:find("\"") then
            modes = modes:gsub(",", path.envsep())
        end
        for _, mode in ipairs(path.splitenv(modes)) do
            table.insert(ret_modes, mode:trim())
        end
    else
        ret_modes = project.modes()
    end
    return ret_modes
end

function _add_PBXFileReference(xcinfo, file_info)
    local obj = {}
    obj.explicitFileType = file_info.explicitFileType
    obj.lastKnownFileType = file_info.lastKnownFileType
    obj.name = file_info.name
    obj.path = file_info.path
    obj.sourceTree = file_info.sourceTree
    obj.includeInIndex = file_info.includeInIndex
    local uuid = xcinfo:gen_uuid()
    xcinfo.sections.PBXFileReference = xcinfo.sections.PBXFileReference or {}
    xcinfo.sections.PBXFileReference[uuid] = obj
    return uuid
end

function _add_PBXGroup(xcinfo, name, sourceTree)
    local obj = {}
    obj.name = name
    obj.sourceTree = sourceTree
    obj.children = {}
    local uuid = xcinfo:gen_uuid()
    xcinfo.sections.PBXGroup = xcinfo.sections.PBXGroup or {}
    xcinfo.sections.PBXGroup[uuid] = obj
    return uuid
end

-- target may be nil.
function _add_XCBuildConfiguration(xcinfo, mode, target)
    local obj = {}
    obj.name = mode
    obj.buildSettings = {}
    -- This allows scripts to read/write files that are not in the Input/Output list of
    -- the phase.
    obj.buildSettings.ENABLE_USER_SCRIPT_SANDBOXING = false
    if target then
        local rules = target:rules()
        local is_app_bundle = false
        if rules["xcode.application"] ~= nil then
            is_app_bundle = true
        end
        if is_app_bundle then
            obj.buildSettings.GENERATE_INFOPLIST_FILE = true
            obj.buildSettings.PRODUCT_NAME = "$(TARGET_NAME)"
        end
    end
    local uuid = xcinfo:gen_uuid()
    xcinfo.sections.XCBuildConfiguration = xcinfo.sections.XCBuildConfiguration or {}
    xcinfo.sections.XCBuildConfiguration[uuid] = obj
    return uuid
end

-- target may be nil.
function _add_XCConfigurationList(xcinfo, target)
    local obj = {}
    local modes = _get_project_modes()
    obj.buildConfigurations = {}
    for _, mode in ipairs(modes) do
        table.insert(obj.buildConfigurations, _add_XCBuildConfiguration(xcinfo, mode, target))
    end
    local uuid = xcinfo:gen_uuid()
    xcinfo.sections.XCConfigurationList = xcinfo.sections.XCConfigurationList or {}
    xcinfo.sections.XCConfigurationList[uuid] = obj
    return uuid
end

function _add_PBXShellScriptBuildPhase(xcinfo, target)
    local obj = {}
    obj.shellScript = [[
cd \"]] .. os.projectdir() .. [[\"
XMAKE_BIN=\"]] .. os.programfile() .. [[\"
# Running xmake scripts.
${XMAKE_BIN} f -y -m ${CONFIGURATION} -p ${PLATFORM_NAME} -a ${NATIVE_ARCH} -o ${BUILD_DIR}
${XMAKE_BIN} build ${TARGET_NAME}\n# Running xmake install scripts.
XMAKE_BUILD_DIR=${BUILD_DIR}/${PLATFORM_NAME}/${NATIVE_ARCH}/${CONFIGURATION}
# Copy files to build path.
if test -e ${CONFIGURATION_BUILD_DIR}
then
    rm -r ${CONFIGURATION_BUILD_DIR}/*
fi
if test -e ${XMAKE_BUILD_DIR}
then
    cp -r ${XMAKE_BUILD_DIR}/* ${CONFIGURATION_BUILD_DIR}
fi
]]
    local uuid = xcinfo:gen_uuid()
    xcinfo.sections.PBXShellScriptBuildPhase = xcinfo.sections.PBXShellScriptBuildPhase or {}
    xcinfo.sections.PBXShellScriptBuildPhase[uuid] = obj
    return uuid
end

function _add_target_files(xcinfo, group, files)
    for _, v in table.orderpairs(files) do
        local file_info = {}
        file_info.name = path.filename(v)
        file_info.path = path.join(project.directory(), v)
        file_info.sourceTree = "\"<absolute>\""
        local ext = path.extension(v)
        if ext == ".h" then
            file_info.lastKnownFileType = "sourcecode.c.h"
        elseif ext == ".c" then
            file_info.lastKnownFileType = "sourcecode.c.c"
        elseif ext == ".m" then
            file_info.lastKnownFileType = "sourcecode.c.objc"
        elseif ext == ".hpp" then
            file_info.lastKnownFileType = "sourcecode.cpp.h"
        elseif ext == ".cpp" then
            file_info.lastKnownFileType = "sourcecode.cpp.cpp"
        elseif ext == ".mm" then
            file_info.lastKnownFileType = "sourcecode.cpp.objcpp"
        elseif ext == ".plist" then
            file_info.lastKnownFileType = "text.plist"
        end
        table.insert(group.children, _add_PBXFileReference(xcinfo, file_info))
    end
end

function _add_PBXNativeTarget(xcinfo, target_name, target)
    local obj = {}
    obj.name = target_name
    obj.productName = target_name
    local rules = target:rules()
    local is_app_bundle = false
    if rules["xcode.application"] ~= nil then
        is_app_bundle = true
    end
    -- Add product file.
    local product_file = {}
    if target:kind() == "static" then
        product_file.explicitFileType = "com.apple.product-type.library.static"
    elseif target:kind() == "shared" then
        product_file.explicitFileType = "com.apple.product-type.library.dynamic"
    elseif target:kind() == "binary" then
        if is_app_bundle then
            product_file.explicitFileType = "wrapper.application"
        else
            product_file.explicitFileType = "com.apple.product-type.tool"
        end 
    end
    if is_app_bundle then
        product_file.name = target:filename() .. ".app"
    else
        product_file.name = target:filename()
    end
    product_file.path = product_file.name
    product_file.sourceTree = "BUILT_PRODUCTS_DIR"
    product_file.includeInIndex = 0
    obj.productReference = _add_PBXFileReference(xcinfo, product_file)
    if is_app_bundle then
        obj.productType = "com.apple.product-type.application"
    else
        obj.productType = product_file.explicitFileType
    end
        -- Add product file to product group.
    local project_obj = xcinfo.sections.PBXProject[xcinfo.root_object]
    local product_group = xcinfo.sections.PBXGroup[project_obj.productRefGroup]
    table.insert(product_group.children, obj.productReference)

    -- Add files.
    local headerfiles = target:headerfiles()
    local sourcefiles = target:sourcefiles()
    obj.headerFileGroup = _add_PBXGroup(xcinfo, "Header Files", "<group>")
    obj.sourceFileGroup = _add_PBXGroup(xcinfo, "Source Files", "<group>")
    local header_group = xcinfo.sections.PBXGroup[obj.headerFileGroup]
    local source_group = xcinfo.sections.PBXGroup[obj.sourceFileGroup]
    _add_target_files(xcinfo, header_group, headerfiles)
    _add_target_files(xcinfo, source_group, sourcefiles)
    obj.mainGroup = _add_PBXGroup(xcinfo, obj.productName, "<group>")
    local main_group = xcinfo.sections.PBXGroup[obj.mainGroup]
    table.insert(main_group.children, obj.headerFileGroup)
    table.insert(main_group.children, obj.sourceFileGroup)
    -- Add configuration list for target.
    obj.buildConfigurationList = _add_XCConfigurationList(xcinfo, target)
    -- Add build phases.
    obj.buildPhases = {}
    table.insert(obj.buildPhases, _add_PBXShellScriptBuildPhase(xcinfo, target))
    local uuid = xcinfo:gen_uuid()
    xcinfo.sections.PBXNativeTarget = xcinfo.sections.PBXNativeTarget or {}
    xcinfo.sections.PBXNativeTarget[uuid] = obj
    return uuid
end

function main(outputdir)
    local xcinfo = {}

    xcinfo.project_dir = outputdir
    xcinfo.project_bundle = (project.name() or path.filename(project.directory())) .. ".xcodeproj"
    xcinfo.project_dir_uuid = string.upper(hash.strhash32(xcinfo.project_dir))
    xcinfo.project_bundle_uuid = string.upper(hash.strhash32(xcinfo.project_bundle))
    xcinfo.uuid_counter = 0
    xcinfo.gen_uuid = function(self)
        local counter = self.uuid_counter
        self.uuid_counter = self.uuid_counter + 1
        return self.project_dir_uuid .. self.project_bundle_uuid .. string.format("%08X", counter)
    end

    -- Used to collect Xcode nodes.
    -- nodes are grouped by their types. For example, all PBXFileReference
    -- nodes will be in xcinfo.sections.PBXFileReference, indexed by their UUIDs.
    xcinfo.sections = {}

    -- Add project node
    local sections = xcinfo.sections
    sections.PBXProject = {}
    local project_uuid = xcinfo:gen_uuid()
    xcinfo.root_object = project_uuid
    sections.PBXProject[project_uuid] = {}
    local project_obj = sections.PBXProject[project_uuid]

    -- collect buildConfigurationList
    project_obj.buildConfigurationList = _add_XCConfigurationList(xcinfo)

    -- collect main group
    project_obj.mainGroup = _add_PBXGroup(xcinfo, nil, "<group>")
    local main_group = xcinfo.sections.PBXGroup[project_obj.mainGroup]

    -- collect product ref group
    project_obj.productRefGroup = _add_PBXGroup(xcinfo, "Products", "<group>");

    -- collect targets.
    project_obj.targets = {}
    for target_name, target in table.orderpairs(project.targets()) do
        local target = _add_PBXNativeTarget(xcinfo, target_name, target)
        table.insert(project_obj.targets, target)
        local target_obj = xcinfo.sections.PBXNativeTarget[target]
        table.insert(main_group.children, target_obj.mainGroup)
    end
    table.insert(main_group.children, project_obj.productRefGroup)

    return xcinfo
end