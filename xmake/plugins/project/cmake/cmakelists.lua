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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        cmakelists.lua
--

-- imports
import("core.project.project")
import("core.tool.compiler")

-- get unix path 
function _get_unix_path(filepath)
    return (path.translate(filepath):gsub('\\', '/'))
end

-- add values from target options
function _add_values_from_targetopts(values, target, name)
	for _, opt in ipairs(target:orderopts()) do
		table.join2(values, table.wrap(opt:get(name)))
	end
end

-- add values from target packages
function _add_values_from_targetpkgs(values, target, name)
    for _, pkg in ipairs(target:orderpkgs()) do
        -- uses them instead of the builtin configs if exists extra package config
        -- e.g. `add_packages("xxx", {links = "xxx"})`
        local configinfo = target:pkgconfig(pkg:name())
        if configinfo and configinfo[name] then
            table.join2(values, configinfo[name])
        else
            -- uses the builtin package configs
            table.join2(values, pkg:get(name))
        end
    end
end


-- add project info
function _add_project(cmakelists)
    cmakelists:print("# project")
    cmakelists:print("cmake_minimum_required(VERSION 3.13.0)")
    local project_name = project.name()
    if project_name then
        local project_info = ""
        local project_version = project.version()
        if project_version then
            project_info = project_info .. " VERSION " .. project_version
        end
        cmakelists:print("project(%s%s LANGUAGES C CXX ASM)", project_name, project_info)
    end
    cmakelists:print("")
end

-- add target: phony
function _add_target_phony(cmakelists, target)
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

-- add target: binary
function _add_target_binary(cmakelists, target)
    cmakelists:print("add_executable(%s \"\")", target:name())
    cmakelists:print("set_target_properties(%s PROPERTIES OUTPUT_NAME \"%s\")", target:name(), target:basename())
    cmakelists:print("set_target_properties(%s PROPERTIES RUNTIME_OUTPUT_DIRECTORY \"%s\")", target:name(), _get_unix_path(target:targetdir()))
end

-- add target: static
function _add_target_static(cmakelists, target)
    cmakelists:print("add_library(%s STATIC \"\")", target:name())
    cmakelists:print("set_target_properties(%s PROPERTIES OUTPUT_NAME \"%s\")", target:name(), target:basename())
    cmakelists:print("set_target_properties(%s PROPERTIES ARCHIVE_OUTPUT_DIRECTORY \"%s\")", target:name(), _get_unix_path(target:targetdir()))
end

-- add target: shared
function _add_target_shared(cmakelists, target)
    cmakelists:print("add_library(%s SHARED \"\")", target:name())
    cmakelists:print("set_target_properties(%s PROPERTIES OUTPUT_NAME \"%s\")", target:name(), target:basename())
    cmakelists:print("set_target_properties(%s PROPERTIES LIBRARY_OUTPUT_DIRECTORY \"%s\")", target:name(), _get_unix_path(target:targetdir()))
end

-- add target dependencies
function _add_target_dependencies(cmakelists, target)
    local deps = target:get("deps")
    if deps then
        cmakelists:printf("add_dependencies(%s", target:name())
        for _, dep in ipairs(deps) do
            cmakelists:write(" " .. dep)
        end
        cmakelists:print(")")
    end
end

-- add target sources
function _add_target_sources(cmakelists, target)
    cmakelists:print("target_sources(%s PRIVATE", target:name())
    for _, sourcefile in ipairs(target:sourcefiles()) do
        cmakelists:print("    " .. _get_unix_path(sourcefile))
    end
    cmakelists:print(")")
end

-- add target include directories
function _add_target_include_directories(cmakelists, target)
    local includedirs = table.wrap(target:get("includedirs"))
    _add_values_from_targetopts(includedirs, target, "includedirs")
    _add_values_from_targetpkgs(includedirs, target, "includedirs")
    if #includedirs > 0 then
        cmakelists:print("target_include_directories(%s PRIVATE", target:name())
        for _, includedir in ipairs(includedirs) do
            cmakelists:print("    " .. _get_unix_path(includedir))
        end
        cmakelists:print(")")
    end

    -- TODO deprecated
    local headerdirs = target:get("headerdirs")
    if headerdirs then
        cmakelists:print("target_include_directories(%s PUBLIC", target:name())
        for _, headerdir in ipairs(headerdirs) do
            cmakelists:print("    " .. _get_unix_path(headerdir))
        end
        cmakelists:print(")")
    end
    local includedirs_interface = target:get("includedirs", {interface = true})
    if includedirs_interface then
        cmakelists:print("target_include_directories(%s INTERFACE", target:name())
        for _, headerdir in ipairs(includedirs_interface) do
            cmakelists:print("    " .. _get_unix_path(headerdir))
        end
        cmakelists:print(")")
    end
    -- export config header directory (deprecated)
    local configheader = target:configheader()
    if configheader then
        cmakelists:print("target_include_directories(%s PUBLIC %s)", target:name(), _get_unix_path(path.directory(configheader)))
    end
end

-- add target compile definitions
function _add_target_compile_definitions(cmakelists, target)
    local defines = table.wrap(target:get("defines"))
    _add_values_from_targetopts(defines, target, "defines")
    _add_values_from_targetpkgs(defines, target, "defines")
    if #defines > 0 then
        cmakelists:print("target_compile_definitions(%s PRIVATE", target:name())
        for _, define in ipairs(defines) do
            cmakelists:print("    " .. define)
        end
        cmakelists:print(")")
    end
end

-- add target compile options
function _add_target_compile_options(cmakelists, target)
    local cflags   = target:get("cflags")
    local cxflags  = target:get("cxflags")
    local cxxflags = target:get("cxxflags")
    local cuflags  = target:get("cuflags")
    if cflags or cxflags or cxxflags or cuflags then
        cmakelists:print("target_compile_options(%s PRIVATE", target:name())
        for _, flag in ipairs(cflags) do
            if compiler.has_flags("c", flag, {target = target}) then
                cmakelists:print("    $<$<COMPILE_LANGUAGE:C>:" .. flag .. ">")
            end
        end
        for _, flag in ipairs(cxflags) do
            if compiler.has_flags("c", flag, {target = target}) then
                cmakelists:print("    $<$<COMPILE_LANGUAGE:C>:" .. flag .. ">")
            end
            if compiler.has_flags("cxx", flag, {target = target}) then
                cmakelists:print("    $<$<COMPILE_LANGUAGE:CXX>:" .. flag .. ">")
            end
        end
        for _, flag in ipairs(cxxflags) do
            if compiler.has_flags("cxx", flag, {target = target}) then
                cmakelists:print("    $<$<COMPILE_LANGUAGE:CXX>:" .. flag .. ">")
            end
        end
        for _, flag in ipairs(cuflags) do
            cmakelists:print("    $<$<COMPILE_LANGUAGE:CUDA>:" .. flag .. ">")
        end
        cmakelists:print(")")
    end
end

-- add target language standards
function _add_target_language_standards(cmakelists, target)
    local cstds = 
    {
        c89         = "90"
    ,   gnu89       = "90" -- TODO add cflags -std=gnu90 if supported
    ,   c99         = "99"
    ,   gnu99       = "99" -- TODO
    ,   c11         = "11"
    ,   gnu11       = "11" -- TODO
    }
    local cxxstds = 
    {
        cxx98       = "98"
    ,   gnuxx98     = "98" -- TODO
    ,   cxx11       = "11"
    ,   gnuxx11     = "11"
    ,   cxx14       = "14"
    ,   gnuxx14     = "14"
    ,   cxx17       = "17"
    ,   gnuxx17     = "17"
    ,   cxx1z       = "17"
    ,   gnuxx1z     = "17"
    ,   cxx2a       = "20"
    ,   gnuxx2a     = "20"
    }
    for _, lang in ipairs(target:get("languages")) do
        local cstd = cstds[lang]
        if cstd then
            cmakelists:print("set_property(TARGET %s PROPERTY C_STANDARD %s)", target:name(), cstd)
            if cstd == "99" or cstd == "11" then
                cmakelists:print("if(MSVC)")
                cmakelists:print("    target_compile_options(%s PRIVATE $<$<COMPILE_LANGUAGE:C>:-TP>)", target:name())
                cmakelists:print("endif()")
            end
        end
        local cxxstd = cxxstds[lang]
        if cxxstd then
            cmakelists:print("set_property(TARGET %s PROPERTY CXX_STANDARD %s)", target:name(), cxxstd)
        end
    end
end

-- add target warnings
function _add_target_warnings(cmakelists, target)
    local flags_gcc = 
    {   
        none  = "-w"
    ,   less  = "-Wall"
    ,   more  = "-Wall"
    ,   all   = "-Wall"
    ,   error = "-Werror"
    }
    local flags_msvc = 
    {   
        none  = "-W0"
    ,   less  = "-W1"
    ,   more  = "-W3"
    ,   all   = "-W3" -- = "-Wall" will enable too more warnings
    ,   error = "-WX"
    }
    local warnings = target:get("warnings")
    if warnings then
        cmakelists:print("if(MSVC)")
        for _, warn in ipairs(warnings) do
            cmakelists:print("    target_compile_options(%s PRIVATE %s)", target:name(), flags_msvc[warn])
        end
        cmakelists:print("else()")
        for _, warn in ipairs(warnings) do
            cmakelists:print("    target_compile_options(%s PRIVATE %s)", target:name(), flags_gcc[warn])
        end
        cmakelists:print("endif()")
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
    ,   faster      = "$<$<CONFIG:Release>:-O2>"
    ,   fastest     = "$<$<CONFIG:Release>:-Ox -fp:fast>"
    ,   smallest    = "$<$<CONFIG:Release>:-O1>"
    ,   aggressive  = "$<$<CONFIG:Release>:-Ox -fp:fast>"
    }
    local optimization = target:get("optimize")
    if optimization then
        cmakelists:print("if(MSVC)")
        cmakelists:print("    target_compile_options(%s PRIVATE %s)", target:name(), flags_msvc[optimization])
        cmakelists:print("else()")
        cmakelists:print("    target_compile_options(%s PRIVATE %s)", target:name(), flags_gcc[optimization])
        cmakelists:print("endif()")
    end
end

-- add target link libraries
function _add_target_link_libraries(cmakelists, target)

    -- add links
    local links = table.wrap(target:get("links"))

    -- add links from target options
    _add_values_from_targetopts(links, target, "links")

    -- add links from target packages
    _add_values_from_targetpkgs(links, target, "links")

    -- add links from target deps
    local targetkind = target:targetkind()
    if targetkind == "binary" or targetkind == "shared" then
        for _, dep in ipairs(target:orderdeps()) do
            local depkind = dep:targetkind()
            if depkind == "static" or depkind == "shared" then
                table.insert(links, dep:name())
            end
        end
    end
    table.join2(links, target:get("syslinks"))
    if #links > 0 then
        cmakelists:print("target_link_libraries(%s PRIVATE", target:name())
        for _, link in ipairs(links) do
            cmakelists:print("    " .. link)
        end
        cmakelists:print(")")
    end
end

-- add target link directories
function _add_target_link_directories(cmakelists, target)
    local linkdirs = table.wrap(target:get("linkdirs"))
    _add_values_from_targetopts(linkdirs, target, "linkdirs")
    _add_values_from_targetpkgs(linkdirs, target, "linkdirs")
    if #linkdirs > 0 then
        cmakelists:print("target_link_directories(%s PRIVATE", target:name())
        for _, linkdir in ipairs(linkdirs) do
            cmakelists:print("    " .. _get_unix_path(linkdir))
        end
        cmakelists:print(")")
    end
end

-- add target link options
function _add_target_link_options(cmakelists, target)
    local shflags = target:get("shflags")
    local ldflags = target:get("ldflags")
    if ldflags or shflags then
        cmakelists:print("target_link_options(%s PRIVATE", target:name())
        for _, flag in ipairs(ldflags) do
            if target:linker():has_flags(flag) then
                cmakelists:print("    " .. flag)
            end
        end
        for _, flag in ipairs(shflags) do
            if target:linker():has_flags(flag) then
                cmakelists:print("    " .. flag)
            end
        end
        cmakelists:print(")")
    end
end

-- TODO export target headers (deprecated)
function _export_target_headers(target)
    local srcheaders, dstheaders = target:headers()
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                os.cp(srcheader, dstheader)
            end
            i = i + 1
        end
    end
end

-- add target
function _add_target(cmakelists, target)

    -- add comment
    cmakelists:print("# target")

    -- is phony target?
    local targetkind = target:targetkind()
    if target:isphony() then
        return _add_target_phony(cmakelists, target)
    elseif targetkind == "binary" then
        _add_target_binary(cmakelists, target)
    elseif targetkind == "static" then
        _add_target_static(cmakelists, target)
    elseif targetkind == "shared" then
        _add_target_shared(cmakelists, target)
    else
        raise("unknown target kind %s", target:targetkind())
    end

    -- TODO export target headers (deprecated)
    _export_target_headers(target)

    -- add target dependencies
    _add_target_dependencies(cmakelists, target)

    -- add target include directories
    _add_target_include_directories(cmakelists, target)

    -- add target compile definitions
    _add_target_compile_definitions(cmakelists, target)

    -- add target language standards
    _add_target_language_standards(cmakelists, target)

    -- add target compile options
    _add_target_compile_options(cmakelists, target)

    -- add target warnings
    _add_target_warnings(cmakelists, target)

    -- add target optimization
    _add_target_optimization(cmakelists, target)

    -- add target link libraries
    _add_target_link_libraries(cmakelists, target)

    -- add target link directories
    _add_target_link_directories(cmakelists, target)

    -- add target link options
    _add_target_link_options(cmakelists, target)

    -- add target sources
    _add_target_sources(cmakelists, target)

    -- end
    cmakelists:print("")
end

-- generate cmakelists
function _generate_cmakelists(cmakelists)

    -- add project info
    _add_project(cmakelists)

    -- add targets
    for _, target in pairs(project.targets()) do
        _add_target(cmakelists, target)
    end
end

-- make
function make(outputdir)

    -- enter project directory
    local oldir = os.cd(os.projectdir())

    -- open the cmakelists
    local cmakelists = io.open(path.join(outputdir, "CMakeLists.txt"), "w")

    -- generate cmakelists
    _generate_cmakelists(cmakelists)

    -- close the cmakelists
    cmakelists:close()
 
    -- leave project directory
    os.cd(oldir)
end
