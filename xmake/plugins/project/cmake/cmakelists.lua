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
-- @file        cmakelists.lua
--

-- imports
import("core.base.colors")
import("core.project.project")
import("core.project.config")
import("core.tool.compiler")
import("core.base.semver")
import("core.base.hashset")
import("core.project.rule")
import("core.platform.platform")
import("lib.detect.find_tool")
import("private.utils.batchcmds")
import("private.utils.target", {alias = "target_utils"})
import("plugins.project.utils.target_cmds", {rootdir = os.programdir()})
import("rules.c++.modules.support", {alias = "module_support", rootdir = os.programdir()})

-- get cmake version
function _get_cmake_version()
    local cmake_version = _g.cmake_version
    if not cmake_version then
        local cmake = find_tool("cmake", {version = true})
        if cmake and cmake.version then
            cmake_version = semver.new(cmake.version)
        end
        _g.cmake_version = cmake_version
    end
    return cmake_version
end

-- has c++ modules sources
function _has_cxxmodules_sources()
    for _, target in ipairs(project.ordertargets()) do
        if module_support.contains_modules(target) then
            return true
        end
    end
end

-- get minimal cmake version
function _get_cmake_minver()
    local cmake_minver = _g.cmake_minver
    if not cmake_minver then
        cmake_minver = _get_cmake_version()
        if cmake_minver then
            if _has_cxxmodules_sources() and cmake_minver:gt("3.28.0") then
                cmake_minver = semver.new("3.28.0")
            elseif cmake_minver:gt("3.15.0") then
                cmake_minver = semver.new("3.15.0")
            end
        end
        if not cmake_minver then
            cmake_minver = semver.new("3.15.0")
        end
        _g.cmake_minver = cmake_minver
    end
    return cmake_minver
end

-- tranlate path
function _translate_path(filepath, outputdir)
    filepath = path.translate(filepath)
    if filepath == "" then
        return ""
    end
    if path.is_absolute(filepath) then
        if filepath:startswith(project.directory()) then
            return path.relative(filepath, outputdir)
        end
        return filepath
    else
        return path.relative(path.absolute(filepath), outputdir)
    end
end

-- escape path
function _escape_path(filepath)
    if is_host("windows") then
        filepath = path.unix(filepath)
        filepath = filepath:gsub(' ', '\\ ')
    end
    return filepath
end

-- escape path in flag
-- @see https://github.com/xmake-io/xmake/issues/3161
function _escape_path_in_flag(target, flag)
    if is_host("windows") then
        -- e.g. /ManifestInput:..\..\, /def:xxx, -isystem c:\xxx, -Ic:\..
        if flag:find("\\", 1, true) then
            flag = _escape_path(flag)
        end
    end
    return flag
end

-- get relative unix path
function _get_relative_unix_path(filepath, outputdir)
    filepath = _translate_path(filepath, outputdir)
    filepath = _escape_path(path.translate(filepath))
    return os.args(filepath)
end

-- get relative unix path to the cmake path
-- @see https://github.com/xmake-io/xmake/issues/2026
function _get_relative_unix_path_to_cmake(filepath, outputdir)
    filepath = _translate_path(filepath, outputdir)
    filepath = path.unix(path.translate(filepath))
    if filepath and not path.is_absolute(filepath) then
        filepath = "${CMAKE_SOURCE_DIR}/" .. filepath
    end
    return os.args(filepath)
end

-- get enabled languages
function _get_project_languages()
    local languages = {}
    for _, target in ipairs(project.ordertargets()) do
        for _, sourcekind in ipairs(target:sourcekinds()) do
            if     sourcekind == "cc"  then table.insert(languages, "C")
            elseif sourcekind == "cxx" then table.insert(languages, "CXX")
            elseif sourcekind == "as"  then table.insert(languages, "ASM")
            elseif sourcekind == "cu"  then table.insert(languages, "CUDA")
            end
        end
    end
    languages = table.unique(languages)
    return languages
end

-- get configs from target
function _get_configs_from_target(target, name)
    local values = {}
    if name:find("flags", 1, true) then
        table.join2(values, target:toolconfig(name))
    end
    for _, value in ipairs((target:get_from(name, "*"))) do
        table.join2(values, value)
    end
    if not name:find("flags", 1, true) then -- for includedirs, links ..
        table.join2(values, target:toolconfig(name))
    end
    return table.unique(values)
end

-- Did the current cmake native support for c++ modules?
function _can_native_support_for_cxxmodules()
    local cmake_minver = _get_cmake_minver()
    if cmake_minver and cmake_minver:ge("3.28") then
        return true
    end
end

-- this sourcebatch is built?
function _sourcebatch_is_built(sourcebatch)
    -- we can only use rulename to filter them because sourcekind may be bound to multiple rules
    local rulename = sourcebatch.rulename
    if rulename == "c.build" or rulename == "c++.build"
        or rulename == "asm.build" or rulename == "cuda.build"
        or rulename == "objc.build" or rulename == "objc++.build"
        or rulename == "win.sdk.resource" then
        return true
    end
    if _can_native_support_for_cxxmodules() then
        if rulename == "c++.build.modules" then
            return true
        end
    end
end

-- get c++ modules rules
function _get_cxxmodules_rules()
    return {"c++.build.modules", "c++.build.modules.builder"}
end

-- translate flag
function _translate_flag(flag, outputdir)
    if flag then
        if path.instance_of(flag) then
            flag = flag:clone():set(_get_relative_unix_path_to_cmake(flag:rawstr(), outputdir)):str()
        -- it may be table, https://github.com/xmake-io/xmake/issues/4816
        elseif type(flag) == "string" then
            if path.is_absolute(flag) then
                flag = _get_relative_unix_path_to_cmake(flag, outputdir)
            elseif flag:startswith("-fmodule-file=") then
                flag = "-fmodule-file=" .. _get_relative_unix_path_to_cmake(flag:sub(15), outputdir)
            elseif flag:startswith("-fmodule-mapper=") then
                flag = "-fmodule-mapper=" .. _get_relative_unix_path_to_cmake(flag:sub(17), outputdir)
            elseif flag:match("(.+)=(.+)") then
                local k, v = flag:match("(.+)=(.+)")
                if v and (v:endswith(".ifc") or v:endswith(".map")) then -- e.g. hello=xxx/hello.ifc
                    flag = k .. "=" .. _get_relative_unix_path_to_cmake(v, outputdir)
                end
            end
        end
    end
    return flag
end

-- translate flags
function _translate_flags(flags, outputdir)
    if not flags then
        return
    end
    local result = {}
    for _, flag in ipairs(flags) do
        if type(flag) == "table" and not path.instance_of(flag) then
            for _, v in ipairs(flag) do
                table.insert(result, _translate_flag(v, outputdir))
            end
        else
            table.insert(result, _translate_flag(flag, outputdir))
        end
    end
    return result
end

-- map compiler flags
function _map_compflags(toolname, langkind, name, values)
    local fake_target = {
        is_shared = function() return false end,
        tool = function()
            local program
            if toolname == "cl" then
                program = "cl.exe"
            elseif toolname == "gcc" then
                program = "gcc"
            elseif toolname == "clang" then
                program = "clang"
            end
            return program, toolname
        end,
        sourcekinds = function()
            return langkind == "c" and "cc" or "cxx"
        end
    }
    return compiler.map_flags(langkind, name, values, {target = fake_target})
end

-- split flag with tool prefix, e.g. clang::-Dclang
function _split_flag_with_tool_prefix(flag)
    local prefix
    local splitinfo = flag:split("::")
    if #splitinfo == 2 then
        prefix = splitinfo[1]
        flag = splitinfo[2]
    end
    return prefix, flag
end

-- get flags from fileconfig
function _get_flags_from_fileconfig(fileconfig, outputdir, name)
    local flags = {}
    table.join2(flags, fileconfig[name])
    if fileconfig.force then
        table.join2(flags, fileconfig.force[name])
    end
    flags = _translate_flags(flags, outputdir)
    if #flags > 0 then
        return flags
    end
end

-- get flags from target
-- @see https://github.com/xmake-io/xmake/issues/3594
function _get_flags_from_target(target, flagkind)
    local results = {}
    local flags = _get_configs_from_target(target, flagkind)
    for _, flag in ipairs(flags) do
        local tools = target:extraconf(flagkind, flag, "tools")
        if not flag:find("::", 1, true) and tools then
            for _, toolname in ipairs(tools) do
                table.insert(results, toolname .. "::" .. flag)
            end
        else
            table.insert(results, flag)
        end
    end
    return results
end

-- set compiler
function _set_compiler(cmakelists)
    if config.get("toolchain") then
        local cc = platform.tool("cc")
        if cc then
            cc = path.unix(cc)
            cmakelists:print("set(CMAKE_C_COMPILER \"%s\")", cc)
        end
        local cxx, cxx_name = platform.tool("cxx")
        if cxx then
            if cxx_name == "clang" or cxx_name == "gcc" then
                local dir = path.directory(cxx)
                local name = path.filename(cxx)
                name = name:gsub("clang$", "clang++")
                name = name:gsub("clang%-", "clang++-")
                name = name:gsub("gcc$", "g++")
                name = name:gsub("gcc%-", "g++-")
                if dir ~= '.' then
                    cxx = path.join(dir, name)
                else
                    cxx = name
                end
            end
            cxx = path.unix(cxx)
            cmakelists:print("set(CMAKE_CXX_COMPILER \"%s\")", cxx)
        end
    end
end

-- add project info
function _add_project(cmakelists, outputdir)

    local cmake_minver = _get_cmake_minver()
    cmakelists:print([[# this is the build file for project %s
# it is autogenerated by the xmake build system.
# do not edit by hand.
]], project.name() or "")
    cmakelists:print("# project")
    cmakelists:print("cmake_minimum_required(VERSION %s)", cmake_minver)
    if cmake_minver:ge("3.15.0") then
        -- for MSVC_RUNTIME_LIBRARY
        cmakelists:print("cmake_policy(SET CMP0091 NEW)")
    end

    -- set compilers, we need set it before project( LANGUAGES..)
    -- @see https://github.com/xmake-io/xmake/issues/5448
    _set_compiler(cmakelists)

    -- set project name
    local project_name = project.name()
    if not project_name then
        for _, target in table.orderpairs(project.targets()) do
            project_name = target:name()
        end
    end
    if _can_native_support_for_cxxmodules() then
        cmakelists:print("set(CMAKE_CXX_SCAN_FOR_MODULES ON)")
    end
    if project_name then
        local project_info = ""
        local project_version = project.version()
        if project_version then
            project_info = project_info .. " VERSION " .. project_version
        end
        local languages = _get_project_languages()
        if languages then
            cmakelists:print("project(%s%s LANGUAGES %s)", project_name, project_info, table.concat(languages, " "))
        else
            cmakelists:print("project(%s%s)", project_name, project_info)
        end
    end
    cmakelists:print("")
end

-- add target: phony
function _add_target_phony(cmakelists, target)

    -- https://github.com/xmake-io/xmake/issues/2337
    target:data_set("plugin.project.kind", "cmakelist")

    cmakelists:printf("add_custom_target(%s", target:name())
    local deps = target:get("deps")
    if deps then
        cmakelists:write(" DEPENDS")
        for _, dep in ipairs(deps) do
            cmakelists:write(" " .. dep)
        end
    end
    cmakelists:print(")")
    cmakelists:print("")
end

-- add target: object
function _add_target_object(cmakelists, target, outputdir)
    -- Can't change the output directory of object/intermediate files in CMake
    -- https://stackoverflow.com/questions/46330056/set-output-directory-for-cmake-object-libraries
    cmakelists:print("add_library(%s OBJECT \"\")", target:name())
    cmakelists:print("set_target_properties(%s PROPERTIES LIBRARY_OUTPUT_DIRECTORY \"%s\")", target:name(), _get_relative_unix_path_to_cmake(target:targetdir(), outputdir))
end

-- add target: binary
function _add_target_binary(cmakelists, target, outputdir)
    cmakelists:print("add_executable(%s \"\")", target:name())
    cmakelists:print("set_target_properties(%s PROPERTIES OUTPUT_NAME \"%s\")", target:name(), target:basename())
    cmakelists:print("set_target_properties(%s PROPERTIES RUNTIME_OUTPUT_DIRECTORY \"%s\")", target:name(), _get_relative_unix_path_to_cmake(target:targetdir(), outputdir))
end

-- add target: static
function _add_target_static(cmakelists, target, outputdir)
    cmakelists:print("add_library(%s STATIC \"\")", target:name())
    cmakelists:print("set_target_properties(%s PROPERTIES OUTPUT_NAME \"%s\")", target:name(), target:basename())
    cmakelists:print("set_target_properties(%s PROPERTIES ARCHIVE_OUTPUT_DIRECTORY \"%s\")", target:name(), _get_relative_unix_path_to_cmake(target:targetdir(), outputdir))
end

-- add target: shared
function _add_target_shared(cmakelists, target, outputdir)
    cmakelists:print("add_library(%s SHARED \"\")", target:name())
    cmakelists:print("set_target_properties(%s PROPERTIES OUTPUT_NAME \"%s\")", target:name(), target:basename())
    if target:is_plat("windows") then
        -- @see https://github.com/xmake-io/xmake/issues/2192
        cmakelists:print("set_target_properties(%s PROPERTIES RUNTIME_OUTPUT_DIRECTORY \"%s\")", target:name(), _get_relative_unix_path_to_cmake(target:targetdir(), outputdir))
        cmakelists:print("set_target_properties(%s PROPERTIES ARCHIVE_OUTPUT_DIRECTORY \"%s\")", target:name(), _get_relative_unix_path_to_cmake(target:targetdir(), outputdir))
    else
        cmakelists:print("set_target_properties(%s PROPERTIES LIBRARY_OUTPUT_DIRECTORY \"%s\")", target:name(), _get_relative_unix_path_to_cmake(target:targetdir(), outputdir))
    end
end

-- add target: headeronly
function _add_target_headeronly(cmakelists, target)
    cmakelists:print("add_library(%s INTERFACE)", target:name())
end

-- add target: headeronly
function _add_target_moduleonly(cmakelists, target)
    cmakelists:print("add_custom_target(%s)", target:name())
end

-- add target dependencies
function _add_target_dependencies(cmakelists, target)
    local deps = {}
    for _, dep in ipairs(target:orderdeps()) do
        if not dep:is_object() then
            table.insert(deps, dep:name())
        end
    end

    if #deps ~= 0 then
        cmakelists:printf("add_dependencies(%s", target:name())
        for _, dep in ipairs(deps) do
            cmakelists:write(" " .. dep)
        end
        cmakelists:print(")")
    end
end

function _print_target_sources(cmakelists, target, files, visibility, opt)
    opt = opt or {}
    local has_fileset_support = _get_cmake_version():ge("3.23")
    local fileset = ""
    if has_fileset_support and opt.set then
        fileset = "FILE_SET " .. opt.set .. " FILES"
    end

    cmakelists:print("target_sources(%s %s %s", target:name(), visibility, fileset)
    for _, file in ipairs(files) do
        cmakelists:print("    " .. file)
    end
    cmakelists:print(")")
end

-- add target sources
function _add_target_sources(cmakelists, target, outputdir)
    local has_cuda = false
    local sourcebatches = target:sourcebatches()
    for name, sourcebatch in table.orderpairs(sourcebatches) do
        local public_sources
        local private_sources
        if _sourcebatch_is_built(sourcebatch) then
            local module_sourcebatch = false
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                if _has_cxxmodules_sources() and name == "c++.build.modules" then
                    module_sourcebatch = true
                    local fileconfig = target:fileconfig(sourcefile)
                    if fileconfig and fileconfig.public then
                        public_sources = public_sources or {}
                        table.insert(public_sources, _get_relative_unix_path(sourcefile, outputdir))
                    else
                        private_sources = private_sources or {}
                        table.insert(private_sources, _get_relative_unix_path(sourcefile, outputdir))
                    end
                else
                    private_sources = private_sources or {}
                    table.insert(private_sources, _get_relative_unix_path(sourcefile, outputdir))
                end
            end
            if public_sources then
                cmakelists:print(format("# public sourcefiles from sourcebatch %s for target %s", name, target:fullname()))
                _print_target_sources(cmakelists, target, public_sources, "PUBLIC", {set = module_sourcebatch and "CXX_MODULES"})
            end
            if private_sources then
                cmakelists:print(format("# private sourcefiles from sourcebatch %s for target %s", name, target:fullname()))
                _print_target_sources(cmakelists, target, private_sources, "PRIVATE", {set = module_sourcebatch and "CXX_MODULES"})
            end
        end
        if sourcebatch.sourcekind == "cu" then
            has_cuda = true
        end
    end
    if target:headerfiles() then
        local public_headers
        local private_headers
        for _, headerfile in ipairs(target:headerfiles()) do
            local fileconfig = target:fileconfig(headerfile)
            if fileconfig and fileconfig.public then
                public_headers = public_headers or {}
                table.insert(public_headers, _get_relative_unix_path(headerfile, outputdir))
            else
                private_headers = private_headers or {}
                table.insert(private_headers, _get_relative_unix_path(headerfile, outputdir))
            end
        end
        if public_headers then
            cmakelists:print(format("# public headers for target %s", target:fullname()))
            _print_target_sources(cmakelists, target, public_headers, "PUBLIC", {set = "HEADERS"})
        end
        if private_headers then
            cmakelists:print(format("# private headers for target %s", target:fullname()))
            _print_target_sources(cmakelists, target, private_headers, "PRIVATE", {set = "HEADERS"})
        end
    end
    if has_cuda then
        cmakelists:print("set_target_properties(%s PROPERTIES CUDA_SEPARABLE_COMPILATION ON)", target:name())
        local devlink = target:policy("build.cuda.devlink") or target:values("cuda.build.devlink")
        if devlink ~= nil then
            cmakelists:print("set_target_properties(%s PROPERTIES CUDA_RESOLVE_DEVICE_SYMBOLS %s)", target:name(), devlink and "ON" or "OFF")
        end
    end
end

-- add target source groups
-- @see https://github.com/xmake-io/xmake/issues/1149
function _add_target_source_groups(cmakelists, target, outputdir)
    local filegroups = target:get("filegroups")
    for _, filegroup in ipairs(filegroups) do
        local files = target:extraconf("filegroups", filegroup, "files") or "**"
        local mode = target:extraconf("filegroups", filegroup, "mode")
        local rootdir = target:extraconf("filegroups", filegroup, "rootdir")
        assert(rootdir, "please set root directory, e.g. add_filegroups(%s, {rootdir = 'xxx'})", filegroup)
        local sources = {}
        local recurse_sources = {}
        if path.is_absolute(rootdir) then
            rootdir = _get_relative_unix_path(rootdir, outputdir)
        else
            rootdir = string.format("${CMAKE_CURRENT_SOURCE_DIR}/%s", _get_relative_unix_path(rootdir, outputdir))
        end
        for _, filepattern in ipairs(files) do
            if filepattern:find("**", 1, true) then
                filepattern = filepattern:gsub("%*%*", "*")
                table.insert(recurse_sources, _get_relative_unix_path(path.join(rootdir, filepattern), outputdir))
            else
                table.insert(sources, _get_relative_unix_path(path.join(rootdir, filepattern), outputdir))
            end
        end
        if #sources > 0 then
            cmakelists:print("FILE(GLOB %s_GROUP_SOURCE_LIST %s)", target:name(), table.concat(sources, " "))
            if mode and mode == "plain" then
                cmakelists:print("source_group(%s FILES ${%s_GROUP_SOURCE_LIST})",
                    _get_relative_unix_path(filegroup, outputdir), target:name())
            else
                cmakelists:print("source_group(TREE %s PREFIX %s FILES ${%s_GROUP_SOURCE_LIST})",
                    rootdir, _get_relative_unix_path(filegroup, outputdir), target:name())
            end
        end
        if #recurse_sources > 0 then
            cmakelists:print("FILE(GLOB_RECURSE %s_GROUP_RECURSE_SOURCE_LIST %s)", target:name(), table.concat(recurse_sources, " "))
            if mode and mode == "plain" then
                cmakelists:print("source_group(%s FILES ${%s_GROUP_RECURSE_SOURCE_LIST})",
                    _get_relative_unix_path(filegroup, outputdir), target:name())
            else
                cmakelists:print("source_group(TREE %s PREFIX %s FILES ${%s_GROUP_RECURSE_SOURCE_LIST})",
                    rootdir, _get_relative_unix_path(filegroup, outputdir), target:name())
            end
        end
    end
end

-- add target precompiled header
function _add_target_precompiled_header(cmakelists, target, outputdir)
    local precompiled_header = target:get("pcheader") or target:get("pcxxheader")
    if precompiled_header then
        cmakelists:print("target_precompile_headers(%s PRIVATE", target:name())
        cmakelists:print("    $<$<COMPILE_LANGUAGE:%s>:${CMAKE_CURRENT_SOURCE_DIR}/%s>",
            target:get("pcxxheader") and "CXX" or "C",
            _get_relative_unix_path(precompiled_header, outputdir))
        cmakelists:print(")")
    end
end

-- add target include directories
function _add_target_include_directories(cmakelists, target, outputdir)
    local includedirs = _get_configs_from_target(target, "includedirs")
    if #includedirs > 0 then
        local access_type = target:kind() == "headeronly" and "INTERFACE" or "PRIVATE"
        cmakelists:print("target_include_directories(%s %s", target:name(), access_type)
        for _, includedir in ipairs(includedirs) do
            cmakelists:print("    " .. _get_relative_unix_path(includedir, outputdir))
        end
        cmakelists:print(")")
    end
    local includedirs_interface = target:get("includedirs", {interface = true})
    if includedirs_interface then
        cmakelists:print("target_include_directories(%s INTERFACE", target:name())
        for _, headerdir in ipairs(includedirs_interface) do
            cmakelists:print("    " .. _get_relative_unix_path(headerdir, outputdir))
        end
        cmakelists:print(")")
    end
end

-- add target system include directories
-- we disable system/external includes first, because cmake doesn’t seem to be able to support msvc /external:I
-- https://github.com/xmake-io/xmake/issues/1050
function _add_target_sysinclude_directories(cmakelists, target, outputdir)
    local includedirs = _get_configs_from_target(target, "sysincludedirs")
    if #includedirs > 0 then
        cmakelists:print("target_include_directories(%s SYSTEM PRIVATE", target:name())
        for _, includedir in ipairs(includedirs) do
            cmakelists:print("    " .. _get_relative_unix_path(includedir, outputdir))
        end
        cmakelists:print(")")
    end
    local includedirs_interface = target:get("sysincludedirs", {interface = true})
    if includedirs_interface then
        cmakelists:print("target_include_directories(%s SYSTEM INTERFACE", target:name())
        for _, headerdir in ipairs(includedirs_interface) do
            cmakelists:print("    " .. _get_relative_unix_path(headerdir, outputdir))
        end
        cmakelists:print(")")
    end
end

-- add target framework directories
function _add_target_framework_directories(cmakelists, target, outputdir)
    local frameworkdirs = _get_configs_from_target(target, "frameworkdirs")
    if #frameworkdirs > 0 then
        cmakelists:print("target_compile_options(%s PRIVATE", target:name())
        for _, frameworkdir in ipairs(frameworkdirs) do
            cmakelists:print("    $<$<COMPILE_LANGUAGE:C>:-F" .. _get_relative_unix_path(frameworkdir, outputdir) .. ">")
            cmakelists:print("    $<$<COMPILE_LANGUAGE:CXX>:-F" .. _get_relative_unix_path(frameworkdir, outputdir) .. ">")
            cmakelists:print("    $<$<COMPILE_LANGUAGE:OBJC>:-F" .. _get_relative_unix_path(frameworkdir, outputdir) .. ">")
            cmakelists:print("    $<$<COMPILE_LANGUAGE:OBJCXX>:-F" .. _get_relative_unix_path(frameworkdir, outputdir) .. ">")
        end
        cmakelists:print(")")
        local cmake_minver = _get_cmake_minver()
        if cmake_minver:ge("3.13.0") then
            cmakelists:print("target_link_options(%s PRIVATE", target:name())
        else
            cmakelists:print("target_link_libraries(%s PRIVATE", target:name())
        end
        for _, frameworkdir in ipairs(frameworkdirs) do
            cmakelists:print("    -F" .. _get_relative_unix_path(frameworkdir, outputdir))
        end
        cmakelists:print(")")
    end
    local frameworkdirs_interface = target:get("frameworkdirs", {interface = true})
    if frameworkdirs_interface then
        cmakelists:print("target_compile_options(%s PRIVATE", target:name())
        for _, frameworkdir in ipairs(frameworkdirs_interface) do
            cmakelists:print("    $<$<COMPILE_LANGUAGE:C>:-F" .. _get_relative_unix_path(frameworkdir, outputdir) .. ">")
            cmakelists:print("    $<$<COMPILE_LANGUAGE:CXX>:-F" .. _get_relative_unix_path(frameworkdir, outputdir) .. ">")
            cmakelists:print("    $<$<COMPILE_LANGUAGE:OBJC>:-F" .. _get_relative_unix_path(frameworkdir, outputdir) .. ">")
            cmakelists:print("    $<$<COMPILE_LANGUAGE:OBJCXX>:-F" .. _get_relative_unix_path(frameworkdir, outputdir) .. ">")
        end
        cmakelists:print(")")
    end
end

-- add target compile definitions
function _add_target_compile_definitions(cmakelists, target)
    local defines = _get_configs_from_target(target, "defines")
    if #defines > 0 then
        cmakelists:print("target_compile_definitions(%s PRIVATE", target:name())
        for _, define in ipairs(defines) do
            cmakelists:print("    " .. define)
        end
        cmakelists:print(")")
    end
end

-- add target source files flags
function _add_target_sourcefiles_flags(cmakelists, target, sourcefile, name, outputdir)
    local fileconfig = target:fileconfig(sourcefile)
    if fileconfig then
        local flags = _get_flags_from_fileconfig(fileconfig, outputdir, name)
        if flags and #flags > 0 then
            cmakelists:print("set_source_files_properties("
                .. _get_relative_unix_path_to_cmake(sourcefile, outputdir)
                .. " PROPERTIES COMPILE_OPTIONS")
            local flagstrs = {}
            for _, flag in ipairs(flags) do
                if name == "cxxflags" then
                    table.insert(flagstrs, "$<$<COMPILE_LANGUAGE:CXX>:" .. flag .. ">")
                elseif name == "cflags" then
                    table.insert(flagstrs, "$<$<COMPILE_LANGUAGE:C>:" .. flag .. ">")
                elseif name == "cxflags" then
                    table.insert(flagstrs, "$<$<COMPILE_LANGUAGE:C>:" .. flag .. ">")
                    table.insert(flagstrs, "$<$<COMPILE_LANGUAGE:CXX>:" .. flag .. ">")
                elseif name == "cuflags" then
                    table.insert(flagstrs, "$<$<COMPILE_LANGUAGE:CUDA>:" .. flag .. ">")
                end
            end
            cmakelists:print("    \"%s\"", table.concat(flagstrs, ";"))
            cmakelists:print(")")
        end
    end
end

-- add target compile options
function _add_target_compile_options(cmakelists, target, outputdir)
    local cflags   = _get_flags_from_target(target, "cflags")
    local cxflags  = _get_flags_from_target(target, "cxflags")
    local cxxflags = _get_flags_from_target(target, "cxxflags")
    local cuflags  = _get_flags_from_target(target, "cuflags")
    local toolnames = hashset.new()
    local function _add_target_compile_options_for_compiler(toolname)
        if #cflags > 0 or #cxflags > 0 or #cxxflags > 0 or #cuflags > 0 then
            cmakelists:print("target_compile_options(%s PRIVATE", target:name())
            for _, flag in ipairs(_translate_flags(cflags, outputdir)) do
                local prefix
                prefix, flag = _split_flag_with_tool_prefix(flag)
                if prefix == toolname then
                    flag = _escape_path_in_flag(target, flag)
                    cmakelists:print("    $<$<COMPILE_LANGUAGE:C>:" .. flag .. ">")
                end
                if prefix then
                    toolnames:insert(prefix)
                end
            end
            for _, flag in ipairs(_translate_flags(cxflags, outputdir)) do
                local prefix
                prefix, flag = _split_flag_with_tool_prefix(flag)
                if prefix == toolname then
                    flag = _escape_path_in_flag(target, flag)
                    cmakelists:print("    $<$<COMPILE_LANGUAGE:C>:" .. flag .. ">")
                    cmakelists:print("    $<$<COMPILE_LANGUAGE:CXX>:" .. flag .. ">")
                end
                if prefix then
                    toolnames:insert(prefix)
                end
            end
            for _, flag in ipairs(_translate_flags(cxxflags, outputdir)) do
                local prefix
                prefix, flag = _split_flag_with_tool_prefix(flag)
                if prefix == toolname then
                    flag = _escape_path_in_flag(target, flag)
                    cmakelists:print("    $<$<COMPILE_LANGUAGE:CXX>:" .. flag .. ">")
                end
                if prefix then
                    toolnames:insert(prefix)
                end
            end
            for _, flag in ipairs(_translate_flags(cuflags, outputdir)) do
                local prefix
                prefix, flag = _split_flag_with_tool_prefix(flag)
                if prefix == toolname then
                    flag = _escape_path_in_flag(target, flag)
                    cmakelists:print("    $<$<COMPILE_LANGUAGE:CUDA>:" .. flag .. ">")
                end
                if prefix then
                    toolnames:insert(prefix)
                end
            end
            cmakelists:print(")")
        end
    end
    _add_target_compile_options_for_compiler()
    local compilernames = {
        clang = "Clang",
        clangxx = "Clang",
        gcc = "GNU",
        gxx = "GNU",
        cl = "MSVC",
        link = "MSVC"
    }
    for _, toolname in toolnames:keys() do
        local name = compilernames[toolname]
        if name then
            cmakelists:print("if(CMAKE_COMPILER_ID STREQUAL \"%s\")", name)
            _add_target_compile_options_for_compiler(toolname)
            cmakelists:print("endif()")
        end
    end

    -- add cflags/cxxflags for the specific source files
    local sourcebatches = target:sourcebatches()
    for _, sourcebatch in table.orderpairs(sourcebatches) do
        if _sourcebatch_is_built(sourcebatch) then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                _add_target_sourcefiles_flags(cmakelists, target, sourcefile, "cxxflags", outputdir)
                _add_target_sourcefiles_flags(cmakelists, target, sourcefile, "cflags", outputdir)
                _add_target_sourcefiles_flags(cmakelists, target, sourcefile, "cxflags", outputdir)
                _add_target_sourcefiles_flags(cmakelists, target, sourcefile, "cuflags", outputdir)
            end
        end
    end
end

-- add target values
function _add_target_values(cmakelists, target, name)
    local values = target:get(name)
    if values then
        if name:endswith("s") then
            name = name:sub(1, #name - 1)
        end
        cmakelists:print("if(CMAKE_COMPILER_ID STREQUAL \"MSVC\")")
        local flags_cl = _map_compflags("cl", "c", name, values)
        for _, flag in ipairs(flags_cl) do
            cmakelists:print("    target_compile_options(%s PRIVATE %s)", target:name(), flag)
        end
        cmakelists:print("elseif(CMAKE_COMPILER_ID STREQUAL \"Clang\")")
        local flags_clang = _map_compflags("clang", "c", name, values)
        for _, flag in ipairs(flags_clang) do
            cmakelists:print("    target_compile_options(%s PRIVATE %s)", target:name(), flag)
        end
        cmakelists:print("elseif(CMAKE_COMPILER_ID STREQUAL \"GNU\")")
        local flags_gcc = _map_compflags("gcc", "c", name, values)
        for _, flag in ipairs(flags_gcc) do
            cmakelists:print("    target_compile_options(%s PRIVATE %s)", target:name(), flag)
        end
        cmakelists:print("endif()")
    end
end

-- add target warnings
function _add_target_warnings(cmakelists, target)
    _add_target_values(cmakelists, target, "warnings")
end

-- add target encodings
function _add_target_encodings(cmakelists, target)
    _add_target_values(cmakelists, target, "encodings")
end

-- add target exceptions
function _add_target_exceptions(cmakelists, target)
    local exceptions = target:get("exceptions")
    if exceptions then
        if exceptions == "none" then
            cmakelists:print("string(REPLACE \"/EHsc\" \"\" CMAKE_CXX_FLAGS \"${CMAKE_CXX_FLAGS}\")")
        else
            _add_target_values(cmakelists, target, "exceptions")
        end
    end
end

-- add target languages
function _add_target_languages(cmakelists, target)
    local features =
    {
        c89       = "c_std_90"
    ,   c99       = "c_std_99"
    ,   c11       = "c_std_11"
    ,   c17       = "c_std_17"
    ,   c23       = "c_std_23"
    ,   clatest   = "c_std_latest"
    ,   cxx98     = "cxx_std_98"
    ,   cxx11     = "cxx_std_11"
    ,   cxx14     = "cxx_std_14"
    ,   cxx17     = "cxx_std_17"
    ,   cxx20     = "cxx_std_20"
    ,   cxx23     = "cxx_std_23"
    ,   cxx26     = "cxx_std_26"
    ,   cxxlatest = "cxx_std_latest"
    }
    local languages = target:get("languages")
    if languages then
        for _, lang in ipairs(languages) do
            local has_ext = false
            -- c | c++ | gnu | gnu++
            local flag = lang:replace('xx', '++'):replace('latest', ''):gsub('%d', '')
            if lang:startswith("gnu") then
                lang = 'c' .. lang:sub(4)
                has_ext = true
            end
            local feature = features[lang] or (features[lang:replace("++", "xx")])
            if feature then
                cmakelists:print("set_target_properties(%s PROPERTIES %s_EXTENSIONS %s)", target:name(), flag:endswith('++') and 'CXX' or 'C', has_ext and "ON" or "OFF")
                if feature:endswith('_latest') then
                    if flag:endswith('++') then
                        cmakelists:print('foreach(standard 26 23 20 17 14 11 98)')
                        cmakelists:print('    include(CheckCXXCompilerFlag)')
                        cmakelists:print('    if(CMAKE_COMPILER_ID STREQUAL \"MSVC\")')
                        cmakelists:print('        check_cxx_compiler_flag("/std:%s${standard}" %s_support_%s_standard_${standard})', flag, target:name(), flag)
                        cmakelists:print('    else()')
                        cmakelists:print('        check_cxx_compiler_flag("-std=%s${standard}" %s_support_%s_standard_${standard})', flag, target:name(), flag)
                        cmakelists:print('    endif()')
                        cmakelists:print('    if(%s_support_%s_standard_${standard})', target:name(), flag)
                        cmakelists:print('        target_compile_features(%s PRIVATE cxx_std_${standard})', target:name())
                        cmakelists:print('        break()')
                        cmakelists:print('    endif()')
                        cmakelists:print('endforeach()')
                    else
                        cmakelists:print('foreach(standard 23 17 11 99 90)')
                        cmakelists:print('    include(CheckCCompilerFlag)')
                        cmakelists:print('    if(CMAKE_COMPILER_ID STREQUAL \"MSVC\")')
                        cmakelists:print('        check_c_compiler_flag("/std:%s${standard}" %s_support_%s_standard_${standard})', flag, target:name(), flag)
                        cmakelists:print('    else()')
                        cmakelists:print('        check_c_compiler_flag("-std=%s${standard}" %s_support_%s_standard_${standard})', flag, target:name(), flag)
                        cmakelists:print('    endif()')
                        cmakelists:print('    if(%s_support_%s_standard_${standard})', target:name(), flag)
                        cmakelists:print('        target_compile_features(%s PRIVATE c_std_${standard})', target:name())
                        cmakelists:print('        break()')
                        cmakelists:print('    endif()')
                        cmakelists:print('endforeach()')
                    end
                else
                    cmakelists:print('target_compile_features(%s PRIVATE %s)', target:name(), feature)
                end
            end
        end
    end
end

-- add target optimization
function _add_target_optimization(cmakelists, target)
    local flags_gcc =
    {
        none       = "-O0"
    ,   fast       = "-O1"
    ,   faster     = "-O2"
    ,   fastest    = "-O3"
    ,   smallest   = "-Os"
    ,   aggressive = "-Ofast"
    }
    local flags_msvc =
    {
        none        = "$<$<CONFIG:Debug>:-Od>"
    ,   faster      = "$<$<CONFIG:Release>:-Ox>"
    ,   fastest     = "$<$<CONFIG:Release>:-O2>"
    ,   smallest    = "$<$<CONFIG:Release>:-O1>"
    ,   aggressive  = "$<$<CONFIG:Release>:-O2>"
    }
    local optimization = target:get("optimize")
    if optimization then
        cmakelists:print("if(CMAKE_COMPILER_ID STREQUAL \"MSVC\")")
        cmakelists:print("    target_compile_options(%s PRIVATE %s)", target:name(), flags_msvc[optimization])
        cmakelists:print("else()")
        cmakelists:print("    target_compile_options(%s PRIVATE %s)", target:name(), flags_gcc[optimization])
        cmakelists:print("endif()")
    end
end

-- add target symbols
function _add_target_symbols(cmakelists, target)
    local symbols = target:get("symbols")
    if symbols then
        local flags_gcc = {}
        local flags_msvc = {}
        local levels = hashset.from(table.wrap(symbols))
        if levels:has("debug") then
            table.insert(flags_gcc, "-g")
            if levels:has("edit") then
                table.insert(flags_msvc, "-ZI")
            elseif levels:has("embed") then
                table.insert(flags_msvc, "-Z7")
            else
                table.insert(flags_msvc, "-Zi")
            end
        end
        if levels:has("hidden") then
            table.insert(flags_gcc, "-fvisibility=hidden")
        end
        cmakelists:print("if(CMAKE_COMPILER_ID STREQUAL \"MSVC\")")
        if #flags_msvc > 0 then
            cmakelists:print("    target_compile_options(%s PRIVATE %s)", target:name(), table.concat(flags_msvc, " "))
        end
        cmakelists:print("else()")
        if #flags_gcc > 0 then
            cmakelists:print("    target_compile_options(%s PRIVATE %s)", target:name(), table.concat(flags_gcc, " "))
        end
        cmakelists:print("endif()")
    end
end

-- add target runtimes
--
-- https://github.com/xmake-io/xmake/issues/1661#issuecomment-927979489
-- https://cmake.org/cmake/help/latest/prop_tgt/MSVC_RUNTIME_LIBRARY.html
--
function _add_target_runtimes(cmakelists, target)
    local cmake_minver = _get_cmake_minver()
    if cmake_minver:ge("3.15.0") then
        local runtimes = target:get("runtimes")
        cmakelists:print("if(CMAKE_COMPILER_ID STREQUAL \"MSVC\")")
        if runtimes then
            if runtimes == "MT" then
                runtimes = "MultiThreaded"
            elseif runtimes == "MTd" then
                runtimes = "MultiThreadedDebug"
            elseif runtimes == "MD" then
                runtimes = "MultiThreadedDLL"
            elseif runtimes == "MDd" then
                runtimes = "MultiThreadedDebugDLL"
            end
        else
            runtimes = "MultiThreaded$<$<CONFIG:Debug>:Debug>"
        end
        cmakelists:print('    set_property(TARGET %s PROPERTY', target:name())
        cmakelists:print('        MSVC_RUNTIME_LIBRARY "%s")', runtimes)
        cmakelists:print("endif()")
    end
end

-- add target link libraries
function _add_target_link_libraries(cmakelists, target, outputdir)

    -- add links
    local links      = _get_configs_from_target(target, "links")
    local syslinks   = _get_configs_from_target(target, "syslinks")
    local frameworks = _get_configs_from_target(target, "frameworks")
    if #frameworks > 0 then
        for _, framework in ipairs(frameworks) do
            table.insert(links, "\"-framework " .. framework .. "\"")
        end
    end
    table.join2(links, syslinks)
    if #links > 0 then
        cmakelists:print("target_link_libraries(%s PRIVATE", target:name())
        for _, link in ipairs(links) do
            cmakelists:print("    " .. link)
        end
        cmakelists:print(")")
    end

    -- get c++ modules rules
    local cxxmodules_rules
    if _can_native_support_for_cxxmodules() then
        cxxmodules_rules = _get_cxxmodules_rules()
    end
    if cxxmodules_rules then
        cxxmodules_rules = hashset.from(cxxmodules_rules)
    else
        cxxmodules_rules = hashset.new()
    end

    -- add other object files, maybe from custom rules
    local objectfiles_set = hashset.new()
    local sourcebatches = target:sourcebatches()
    for _, sourcebatch in table.orderpairs(sourcebatches) do
        if _sourcebatch_is_built(sourcebatch) or cxxmodules_rules:has(sourcebatch.rulename) then
            for _, objectfile in ipairs(sourcebatch.objectfiles) do
                objectfiles_set:insert(objectfile)
            end
        end
    end

    local object_deps = {}
    for _, dep in ipairs(target:orderdeps()) do
        if dep:is_object() then
            table.insert(object_deps, dep:name())
            for _, obj in ipairs(dep:objectfiles()) do
                objectfiles_set:insert(obj)
            end
        end
    end


    local has_links = #target:objectfiles() > objectfiles_set:size()
    local key = target:name() .. "_" .. hash.uuid():split("-", {plain = true})[1]
    if has_links then
        cmakelists:print("add_library(target_objectfiles_%s OBJECT IMPORTED GLOBAL)", key)
        cmakelists:print("set_property(TARGET target_objectfiles_%s PROPERTY IMPORTED_OBJECTS", key)
        for _, objectfile in ipairs(target:objectfiles()) do
            if not objectfiles_set:has(objectfile) then
                cmakelists:print("    " .. _get_relative_unix_path_to_cmake(objectfile, outputdir))
            end
        end
    end

    if #object_deps ~= 0 then
        if not has_links then
            cmakelists:print("add_library(target_objectfiles_%s OBJECT IMPORTED GLOBAL)", key)
            cmakelists:print("set_property(TARGET target_objectfiles_%s PROPERTY IMPORTED_OBJECTS", key)
            has_links = true
        end
        for _, dep in ipairs(object_deps) do
            cmakelists:print("    " .. dep)
        end
    end

    if has_links then
        cmakelists:print(")")
        cmakelists:print("target_link_libraries(%s PRIVATE target_objectfiles_%s)", target:name(), key)
    end
end

-- add target link directories
function _add_target_link_directories(cmakelists, target, outputdir)
    local linkdirs = _get_configs_from_target(target, "linkdirs")
    if #linkdirs > 0 then
        local cmake_minver = _get_cmake_minver()
        if cmake_minver:ge("3.13.0") then
            cmakelists:print("target_link_directories(%s PRIVATE", target:name())
            for _, linkdir in ipairs(linkdirs) do
                cmakelists:print("    " .. _get_relative_unix_path(linkdir, outputdir))
            end
            cmakelists:print(")")
        else
            cmakelists:print("if(CMAKE_COMPILER_ID STREQUAL \"MSVC\")")
            cmakelists:print("    target_link_libraries(%s PRIVATE", target:name())
            for _, linkdir in ipairs(linkdirs) do
                cmakelists:print("        -libpath:" .. _get_relative_unix_path(linkdir, outputdir))
            end
            cmakelists:print("    )")
            cmakelists:print("else()")
            cmakelists:print("    target_link_libraries(%s PRIVATE", target:name())
            for _, linkdir in ipairs(linkdirs) do
                cmakelists:print("        -L" .. _get_relative_unix_path(linkdir, outputdir))
            end
            cmakelists:print("    )")
            cmakelists:print("endif()")
        end
    end
end

-- add target link options
function _add_target_link_options(cmakelists, target, outputdir)
    local ldflags = _get_flags_from_target(target, "ldflags")
    local shflags = _get_flags_from_target(target, "shflags")
    local toolnames = hashset.new()
    local function _add_target_link_options_for_linker(toolname)
        if #ldflags > 0 or #shflags > 0 then
            local flags = {}
            for _, flag in ipairs(table.unique(table.join(ldflags, shflags))) do
                table.insert(flags, _translate_flag(flag, outputdir))
            end
            if #flags > 0 then
                local cmake_minver = _get_cmake_minver()
                if cmake_minver:ge("3.13.0") then
                    cmakelists:print("target_link_options(%s PRIVATE", target:name())
                else
                    cmakelists:print("target_link_libraries(%s PRIVATE", target:name())
                end
                for _, flag in ipairs(flags) do
                    local prefix
                    prefix, flag = _split_flag_with_tool_prefix(flag)
                    if prefix == toolname then
                        flag = _escape_path_in_flag(target, flag)
                        -- @see https://github.com/xmake-io/xmake/issues/4196
                        if cmake_minver:ge("3.12.0") and #os.argv(flag) > 1 then
                            cmakelists:print("    " .. os.args("SHELL:" .. flag))
                        else
                            cmakelists:print("    " .. flag)
                        end
                    end
                    if prefix then
                        toolnames:insert(prefix)
                    end
                end
                cmakelists:print(")")
            end
        end
    end
    _add_target_link_options_for_linker()
    local linkernames = {
        clang = "Clang",
        clangxx = "Clang",
        gcc = "GNU",
        gxx = "GNU",
        cl = "MSVC",
        link = "MSVC"
    }
    for _, toolname in toolnames:keys() do
        local name = linkernames[toolname]
        if name then
            cmakelists:print("if(CMAKE_COMPILER_ID STREQUAL \"%s\")", name)
            _add_target_link_options_for_linker(toolname)
            cmakelists:print("endif()")
        end
    end
end

-- get command string
function _get_command_string(cmd, outputdir)
    local kind = cmd.kind
    local opt = cmd.opt
    if cmd.program then
        -- @see https://github.com/xmake-io/xmake/discussions/2156
        local argv = {}
        for _, v in ipairs(cmd.argv) do
            table.insert(argv, _translate_flag(v, outputdir))
        end
        local command = _escape_path(cmd.program) .. " " .. os.args(argv)
        if opt and opt.curdir then
            command = "${CMAKE_COMMAND} -E chdir " .. _get_relative_unix_path_to_cmake(opt.curdir, outputdir) .. " " .. command
        end
        return command
    elseif kind == "cp" then
        if os.isdir(cmd.srcpath) then
            return string.format("${CMAKE_COMMAND} -E copy_directory %s %s",
                _get_relative_unix_path_to_cmake(cmd.srcpath, outputdir), _get_relative_unix_path_to_cmake(cmd.dstpath, outputdir))
        else
            return string.format("${CMAKE_COMMAND} -E copy %s %s",
                _get_relative_unix_path_to_cmake(cmd.srcpath, outputdir), _get_relative_unix_path_to_cmake(cmd.dstpath, outputdir))
        end
    elseif kind == "rm" then
        return string.format("${CMAKE_COMMAND} -E rm -rf %s", _get_relative_unix_path_to_cmake(cmd.filepath, outputdir))
    elseif kind == "rmdir" then
        return string.format("${CMAKE_COMMAND} -E rm -rf %s", _get_relative_unix_path_to_cmake(cmd.dir, outputdir))
    elseif kind == "mv" then
        return string.format("${CMAKE_COMMAND} -E rename %s %s",
            _get_relative_unix_path_to_cmake(cmd.srcpath, outputdir), _get_relative_unix_path_to_cmake(cmd.dstpath, outputdir))
    elseif kind == "cd" then
        return string.format("cd %s", _get_relative_unix_path_to_cmake(cmd.dir, outputdir))
    elseif kind == "mkdir" then
        return string.format("${CMAKE_COMMAND} -E make_directory %s", _get_relative_unix_path_to_cmake(cmd.dir, outputdir))
    elseif kind == "show" then
        return string.format("echo %s", colors.ignore(cmd.showtext))
    end
end

-- add target custom commands for batchcmds
function _add_target_custom_commands_for_batchcmds(cmakelists, target, outputdir, suffix, cmds)
    if #cmds == 0 then
        return
    end
    if suffix == "before" then
        -- ADD_CUSTOM_COMMAND and PRE_BUILD did not work as I expected,
        -- so we need to use add_dependencies and fake target to support it.
        --
        -- @see https://gitlab.kitware.com/cmake/cmake/-/issues/17802
        --
        local key = target:name() .. "_" .. hash.uuid():split("-", {plain = true})[1]
        cmakelists:print("add_custom_command(OUTPUT output_%s", key)
        for _, cmd in ipairs(cmds) do
            local command = _get_command_string(cmd, outputdir)
            if command then
                cmakelists:print("    COMMAND %s", command)
            end
        end
        cmakelists:print("    VERBATIM")
        cmakelists:print(")")
        cmakelists:print("add_custom_target(target_%s", key)
        cmakelists:print("    DEPENDS output_%s", key)
        cmakelists:print(")")
        cmakelists:print("add_dependencies(%s target_%s)", target:name(), key)
    elseif suffix == "after" then
        cmakelists:print("add_custom_command(TARGET %s", target:name())
        cmakelists:print("    POST_BUILD")
        for _, cmd in ipairs(cmds) do
            local command = _get_command_string(cmd, outputdir)
            if command then
                cmakelists:print("    COMMAND %s", command)
            end
        end
        cmakelists:print("    VERBATIM")
        cmakelists:print(")")
    end
end

-- add target custom commands
function _add_target_custom_commands(cmakelists, target, outputdir)

    -- ignore c++ modules rules
    local ignored_rules
    if _can_native_support_for_cxxmodules() then
        ignored_rules = _get_cxxmodules_rules()
    end

    -- add before commands
    -- we use irpairs(groups), because the last group that should be given the highest priority.
    -- rule.on_buildcmd_files should also be executed before building the target, as cmake PRE_BUILD does not work.
    local cmds_before = target_cmds.get_target_buildcmds(target, {ignored_rules = ignored_rules, stages = {"before", "on"}})
    _add_target_custom_commands_for_batchcmds(cmakelists, target, outputdir, "before", cmds_before)

    -- add after commands
    local cmds_after = target_cmds.get_target_buildcmds(target, {ignored_rules = ignored_rules, stages = {"after"}})
    _add_target_custom_commands_for_batchcmds(cmakelists, target, outputdir, "after", cmds_after)
end

-- add target
function _add_target(cmakelists, target, outputdir)

    -- add comment
    cmakelists:print("# target")

    -- is phony target?
    if target:is_phony() then
        return _add_target_phony(cmakelists, target)
    elseif target:is_object() then
        _add_target_object(cmakelists, target, outputdir)
    elseif target:is_binary() then
        _add_target_binary(cmakelists, target, outputdir)
    elseif target:is_static() then
        _add_target_static(cmakelists, target, outputdir)
    elseif target:is_shared() then
        _add_target_shared(cmakelists, target, outputdir)
    elseif target:is_headeronly() then
        _add_target_headeronly(cmakelists, target)
        _add_target_include_directories(cmakelists, target, outputdir)
        return
    elseif target:is_moduleonly() then
        _add_target_moduleonly(cmakelists, target)
        return
    else
        raise("unknown target kind %s", target:kind())
    end

    -- add target dependencies
    _add_target_dependencies(cmakelists, target)

    -- add target custom commands
    -- we need to call it first for running all rules, these rules will change some flags, e.g. c++modules
    _add_target_custom_commands(cmakelists, target, outputdir)

    -- add target precompilied header
    _add_target_precompiled_header(cmakelists, target, outputdir)

    -- add target include directories
    _add_target_include_directories(cmakelists, target, outputdir)

    -- add target system include directories
    _add_target_sysinclude_directories(cmakelists, target, outputdir)

    -- add target framework directories
    _add_target_framework_directories(cmakelists, target, outputdir)

    -- add target compile definitions
    _add_target_compile_definitions(cmakelists, target)

    -- add target compile options
    _add_target_compile_options(cmakelists, target, outputdir)

    -- add target warnings
    _add_target_warnings(cmakelists, target)

    -- add target exceptions
    _add_target_encodings(cmakelists, target)

    -- add target exceptions
    _add_target_exceptions(cmakelists, target)

    -- add target languages
    _add_target_languages(cmakelists, target)

    -- add target optimization
    _add_target_optimization(cmakelists, target)

    -- add target symbols
    _add_target_symbols(cmakelists, target)

    -- add target runtimes
    _add_target_runtimes(cmakelists, target)

    -- add target link libraries
    _add_target_link_libraries(cmakelists, target, outputdir)

    -- add target link directories
    _add_target_link_directories(cmakelists, target, outputdir)

    -- add target link options
    _add_target_link_options(cmakelists, target, outputdir)

    -- add target sources
    _add_target_sources(cmakelists, target, outputdir)

    -- add target source groups
    _add_target_source_groups(cmakelists, target, outputdir)

    -- end
    cmakelists:print("")
end

-- generate cmakelists
function _generate_cmakelists(cmakelists, outputdir)

    -- add project info
    _add_project(cmakelists, outputdir)

    -- add targets
    for _, target in table.orderpairs(project.targets()) do
        _add_target(cmakelists, target, outputdir)
    end
end

function make(outputdir)
    local oldir = os.cd(os.projectdir())
    local cmakelists = io.open(path.join(outputdir, "CMakeLists.txt"), "w")
    target_cmds.prepare_targets()
    _generate_cmakelists(cmakelists, outputdir)
    cmakelists:close()
    os.cd(oldir)
end
