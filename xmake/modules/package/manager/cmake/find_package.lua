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
-- @file        find_package.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.target")
import("lib.detect.find_tool")

local _cmake_internal_flags_variables = {
    -- c flags
    "CMAKE_C_FLAGS",
    "CMAKE_C_FLAGS_DEBUG",
    "CMAKE_C_FLAGS_RELEASE",
    "CMAKE_C_FLAGS_MINSIZEREL",
    "CMAKE_C_FLAGS_RELWITHDEBINFO",
    "CMAKE_C_FLAGS_INIT",
    "CMAKE_C_FLAGS_DEBUG_INIT",
    "CMAKE_C_FLAGS_RELEASE_INIT",
    "CMAKE_C_FLAGS_MINSIZEREL_INIT",
    "CMAKE_C_FLAGS_RELWITHDEBINFO_INIT",
    "CMAKE_C_FLAGS",

    -- c++ flags
    "CMAKE_CXX_FLAGS",
    "CMAKE_CXX_FLAGS_DEBUG",
    "CMAKE_CXX_FLAGS_RELEASE",
    "CMAKE_CXX_FLAGS_MINSIZEREL",
    "CMAKE_CXX_FLAGS_RELWITHDEBINFO",
    "CMAKE_CXX_FLAGS_INIT",
    "CMAKE_CXX_FLAGS_DEBUG_INIT",
    "CMAKE_CXX_FLAGS_RELEASE_INIT",
    "CMAKE_CXX_FLAGS_MINSIZEREL_INIT",
    "CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT",

    -- linker flags
    "CMAKE_EXE_LINKER_FLAGS",
    "CMAKE_EXE_LINKER_FLAGS_DEBUG",
    "CMAKE_EXE_LINKER_FLAGS_RELEASE",
    "CMAKE_EXE_LINKER_FLAGS_MINSIZEREL",
    "CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO",
    "CMAKE_EXE_LINKER_FLAGS_INIT",
    "CMAKE_EXE_LINKER_FLAGS_DEBUG_INIT",
    "CMAKE_EXE_LINKER_FLAGS_RELEASE_INIT",
    "CMAKE_EXE_LINKER_FLAGS_MINSIZEREL_INIT",
    "CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO_INIT",
    "CMAKE_SHARED_LINKER_FLAGS",
    "CMAKE_SHARED_LINKER_FLAGS_DEBUG",
    "CMAKE_SHARED_LINKER_FLAGS_RELEASE",
    "CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL",
    "CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO",
    "CMAKE_SHARED_LINKER_FLAGS_INIT",
    "CMAKE_SHARED_LINKER_FLAGS_DEBUG_INIT",
    "CMAKE_SHARED_LINKER_FLAGS_RELEASE_INIT",
    "CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL_INIT",
    "CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO_INIT",
    "CMAKE_STATIC_LINKER_FLAGS",
    "CMAKE_STATIC_LINKER_FLAGS_DEBUG",
    "CMAKE_STATIC_LINKER_FLAGS_RELEASE",
    "CMAKE_STATIC_LINKER_FLAGS_MINSIZEREL",
    "CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO",
    "CMAKE_STATIC_LINKER_FLAGS_INIT",
    "CMAKE_STATIC_LINKER_FLAGS_DEBUG_INIT",
    "CMAKE_STATIC_LINKER_FLAGS_RELEASE_INIT",
    "CMAKE_STATIC_LINKER_FLAGS_MINSIZEREL_INIT",
    "CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO_INIT",

    -- msvc
    "CMAKE_MSVC_RUNTIME_LIBRARY",

    -- windows
    -- https://github.com/Kitware/CMake/blob/e66e0b2cfefaf61fa995a0aa117df31e680b1c7e/Source/cmLocalGenerator.cxx#L1604
    -- https://github.com/Kitware/CMake/blob/e66e0b2cfefaf61fa995a0aa117df31e680b1c7e/Modules/Platform/Windows-MSVC.cmake#L404
    "CMAKE_CXX_CREATE_WIN32_EXE",
    "CMAKE_CXX_CREATE_CONSOLE_EXE"
}

-- exclude cmake internal definitions https://github.com/xmake-io/xmake/issues/5217
function _should_exclude(define)
    local name = define:split("=")[1]
    return table.contains({"CMAKE_INTDIR", "_DEBUG", "NDEBUG"}, name)
end

-- map xmake mode to cmake mode
function _cmake_mode(mode)
    if mode == "debug" then return "Debug"
    elseif mode == "releasedbg" then return "RelWithDebInfo"
    elseif mode == "minsizerel" then return "MinSizeRel"
    else return "Release"
    end
end

-- find package
function _find_package(cmake, name, opt)
    local is_windows = os.host() == "windows"

    -- get work directory
    local workdir = os.tmpfile() .. ".dir"
    os.tryrm(workdir)
    os.mkdir(workdir)

    -- generate fake ninja
    local ninja_version = "1.10.2"
    local ninjascript
    if is_windows then
        ninjascript = path.join(workdir, "ninja1.bat")
        io.writefile(ninjascript, "@echo off\necho " .. ninja_version)
    else
        ninjascript = path.join(workdir, "ninja1.sh")
        io.writefile(ninjascript, "#!/bin/bash\necho " .. ninja_version)
        os.vrunv("chmod", {"+x", ninjascript}, {curdir = workdir, envs = envs})
    end

    -- generate main.cpp
    io.writefile(path.join(workdir, "main.cpp"), "")

    -- generate main-info.cmake.in
    local info_cmake_in_file = io.open(path.join(workdir, "main-info.cmake.in"), "w")
    info_cmake_in_file:print("set(INFO_INCLUDE_DIRS @INFO_INCLUDE_DIRS@)")
    info_cmake_in_file:print("set(INFO_LINK_DIRS @INFO_LINK_DIRS@)")
    info_cmake_in_file:print("set(INFO_COMPILE_DEFINITIONS @INFO_COMPILE_DEFINITIONS@)")
    info_cmake_in_file:print("set(INFO_COMPILE_OPTIONS @INFO_COMPILE_OPTIONS@)")
    info_cmake_in_file:print("set(INFO_LINK_OPTIONS @INFO_LINK_OPTIONS@)")
    info_cmake_in_file:print("set(INFO_LINK_LIBRARIES @INFO_LINK_LIBRARIES@)")
    info_cmake_in_file:close()

    -- generate CMakeLists.txt
    local filepath = path.join(workdir, "CMakeLists.txt")
    local cmakefile = io.open(filepath, "w")
    if cmake.version then
        cmakefile:print("cmake_minimum_required(VERSION %s)", cmake.version)
    end
    cmakefile:print("project(main)")

    -- unset CMake internal flags variables
    for _, var in ipairs(_cmake_internal_flags_variables) do
        cmakefile:print("set(%s \"\")", var)
    end

    -- e.g. OpenCV 4.1.1, Boost COMPONENTS regex system
    local requirestr = name
    local configs = opt.configs or {}
    if opt.require_version and opt.require_version ~= "latest" then
        requirestr = requirestr .. " " .. opt.require_version
    end

    -- set search mode, e.g. config, module
    -- it will be both mode if do not set this config.
    -- e.g. https://cmake.org/cmake/help/latest/command/find_package.html#id4
    if configs.search_mode then
        requirestr = requirestr .. " " .. configs.search_mode:upper()
    end

    -- use opt.components is for backward compatibility
    local componentstr = ""
    local components = configs.components or opt.components
    if components and #components > 0 then
        componentstr = "COMPONENTS"
        for _, component in ipairs(components) do
            componentstr = componentstr .. " " .. component
        end
    end
    local moduledirs = configs.moduledirs or opt.moduledirs
    if moduledirs then
        for _, moduledir in ipairs(moduledirs) do
            cmakefile:print("list(APPEND CMAKE_MODULE_PATH \"%s\")", (moduledir:gsub("\\", "/")))
        end
    end
    -- https://github.com/xmake-io/xmake/issues/6296
    local prefixdirs = configs.prefixdirs or opt.prefixdirs
    if prefixdirs then
        for _, prefixdir in ipairs(prefixdirs) do
            cmakefile:print("list(APPEND CMAKE_PREFIX_PATH \"%s\")", (prefixdir:gsub("\\", "/")))
        end
    end

    -- e.g. set(Boost_USE_STATIC_LIB ON)
    local presets = configs.presets or opt.presets
    if presets then
        for k, v in pairs(presets) do
            if type(v) == "boolean" then
                cmakefile:print("set(%s %s)", k, v and "ON" or "OFF")
            else
                cmakefile:print("set(%s %s)", k, tostring(v))
            end
        end
    end
    
    -- find package manually
    local find_script = configs.find_script or opt.find_script
    if find_script then
        cmakefile:print(find_script)
    else
        cmakefile:print("find_package(%s REQUIRED %s)", requirestr, componentstr)
    end

    -- add target
    local target_type = configs.target_type or opt.target_type
    local is_executable
    if not target_type then
        is_executable = true
        cmakefile:print("add_executable(${PROJECT_NAME})")
    elseif target_type == "shared" then
        cmakefile:print("add_library(${PROJECT_NAME} SHARED)")
    elseif target_type == "static" then
        cmakefile:print("add_library(${PROJECT_NAME} STATIC)")
    else
        is_executable = true
        cmakefile:print("add_executable(${PROJECT_NAME})")
    end
    cmakefile:print("target_sources(${PROJECT_NAME} PRIVATE main.cpp)")

    -- set target properties
    if is_executable and is_windows and (configs.win32 or opt.win32) then
        cmakefile:print("set_target_properties(${PROJECT_NAME} PROPERTIES WIN32_EXECUTABLE TRUE)")
    end

    -- setup include directories
    local includedirs = ""
    if configs.include_directories then
        includedirs = table.concat(table.wrap(configs.include_directories), " ")
    else
        includedirs = ("${%s_INCLUDE_DIR} ${%s_INCLUDE_DIRS}"):format(name, name)
        includedirs = includedirs .. (" ${%s_INCLUDE_DIR} ${%s_INCLUDE_DIRS}"):format(name:upper(), name:upper())
    end
    cmakefile:print("target_include_directories(${PROJECT_NAME} PRIVATE %s)", includedirs)

    -- reserved for backword compatibility
    cmakefile:print("target_include_directories(${PROJECT_NAME} PRIVATE ${%s_CXX_INCLUDE_DIRS})", name)

    -- setup link library/target
    local linklibs = ""
    if configs.link_libraries then
        linklibs = table.concat(table.wrap(configs.link_libraries), " ")
    else
        linklibs = ("${%s_LIBRARY} ${%s_LIBRARIES} ${%s_LIBS}"):format(name, name, name)
        linklibs = linklibs .. (" ${%s_LIBRARY} ${%s_LIBRARIES} ${%s_LIBS}"):format(name:upper(), name:upper(), name:upper())
    end
    cmakefile:print("target_link_libraries(${PROJECT_NAME} PRIVATE %s)", linklibs)

    -- link target manually
    local link_script = configs.link_script or opt.link_script
    if link_script then
        cmakefile:print(link_script)
    end

    -- setup generating information
    cmakefile:print("set(INFO_INCLUDE_DIRS $<TARGET_PROPERTY:${PROJECT_NAME},INCLUDE_DIRECTORIES>)")
    cmakefile:print("set(INFO_LINK_DIRS $<TARGET_PROPERTY:${PROJECT_NAME},LINK_DIRECTORIES>)")
    cmakefile:print("set(INFO_COMPILE_DEFINITIONS $<TARGET_PROPERTY:${PROJECT_NAME},COMPILE_DEFINITIONS>)")
    cmakefile:print("set(INFO_COMPILE_OPTIONS $<TARGET_PROPERTY:${PROJECT_NAME},COMPILE_OPTIONS>)")
    cmakefile:print("set(INFO_LINK_OPTIONS $<TARGET_PROPERTY:${PROJECT_NAME},LINK_OPTIONS>)")
    cmakefile:print("set(INFO_LINK_LIBRARIES $<TARGET_PROPERTY:${PROJECT_NAME},LINK_LIBRARIES>)")
    cmakefile:print("configure_file(\"main-info.cmake.in\" \"${CMAKE_BINARY_DIR}/main-info.cmake.tmp\" @ONLY)")
    cmakefile:print("file(GENERATE OUTPUT \"${CMAKE_BINARY_DIR}/main-info.cmake\" INPUT \"${CMAKE_BINARY_DIR}/main-info.cmake.tmp\")")

    cmakefile:close()
    if option.get("diagnosis") then
        local cmakedata = io.readfile(filepath)
        cprint("finding it from the generated CMakeLists.txt:\n${dim}%s", cmakedata)
    end

    -- run cmake
    local envs = configs.envs or opt.envs or {}
    envs.CMAKE_BUILD_TYPE = envs.CMAKE_BUILD_TYPE or _cmake_mode(opt.mode or "release")
    
    local builddir = path.join(workdir, "build")
    try {
        function() 
            return os.vrunv(cmake.program,
                {
                    "-S",
                    workdir,
                    "-B",
                    builddir,
                    "-G",
                    "Ninja",
                    "-DCMAKE_MAKE_PROGRAM=" .. ninjascript,
                },
                {
                    curdir = workdir,
                    envs = envs
                }
            )
        end
    }

    -- generate strip-info.cmake
    local stripscriptpath = path.join(workdir, "strip-info.cmake")
    local stripscript = io.open(stripscriptpath, "w")
    stripscript:print("include(${INPUT_FILE})")
    stripscript:print("function(_strip_genex _var)")
    stripscript:print("    string(GENEX_STRIP \"${${_var}}\" _var_no_genex)")
    stripscript:print("    if(NOT \"${_var_no_genex}\" STREQUAL \"${${_var}}\")")
    stripscript:print("        unset(${_var} PARENT_SCOPE)")
    stripscript:print("    endif()")
    stripscript:print("endfunction()")

    stripscript:print("function(_list_to_table _list _table)")
    stripscript:print("    if(_list AND (NOT \"${${_list}}\" STREQUAL \"\"))")
    stripscript:print("        string(REPLACE \";\" \"\\\",\\n        \\\"\" _result \"${${_list}}\")")
    stripscript:print("        set(_result \"{\n        \\\"${_result}\\\"    \\n    }\")")
    stripscript:print("        set(${_table} ${_result} PARENT_SCOPE)")
    stripscript:print("        return()")
    stripscript:print("    endif()")
    stripscript:print("    set(${_table} \"nil\" PARENT_SCOPE)")
    stripscript:print("endfunction()")

    stripscript:print("_strip_genex(INFO_INCLUDE_DIRS)")
    stripscript:print("_strip_genex(INFO_LINK_DIRS)")
    stripscript:print("_strip_genex(INFO_COMPILE_DEFINITIONS)")
    stripscript:print("_strip_genex(INFO_COMPILE_OPTIONS)")
    stripscript:print("_strip_genex(INFO_LINK_OPTIONS)")
    stripscript:print("_strip_genex(INFO_LINK_LIBRARIES)")

    stripscript:print("_list_to_table(INFO_INCLUDE_DIRS INFO_INCLUDE_DIRS_TABLE)")
    stripscript:print("_list_to_table(INFO_LINK_DIRS INFO_LINK_DIRS_TABLE)")
    stripscript:print("_list_to_table(INFO_COMPILE_DEFINITIONS INFO_COMPILE_DEFINITIONS_TABLE)")
    stripscript:print("_list_to_table(INFO_COMPILE_OPTIONS INFO_COMPILE_OPTIONS_TABLE)")
    stripscript:print("_list_to_table(INFO_LINK_OPTIONS INFO_LINK_OPTIONS_TABLE)")
    stripscript:print("_list_to_table(INFO_LINK_LIBRARIES INFO_LINK_LIBRARIES_TABLE)")

    stripscript:print("set(_content \"{")
    stripscript:print("    INCLUDE_DIRS = ${INFO_INCLUDE_DIRS_TABLE},")
    stripscript:print("    LINK_DIRS = ${INFO_LINK_DIRS_TABLE},")
    stripscript:print("    COMPILE_DEFINITIONS = ${INFO_COMPILE_DEFINITIONS_TABLE},")
    stripscript:print("    COMPILE_OPTIONS = ${INFO_COMPILE_OPTIONS_TABLE},")
    stripscript:print("    LINK_OPTIONS = ${INFO_LINK_OPTIONS_TABLE},")
    stripscript:print("    LINK_LIBRARIES = ${INFO_LINK_LIBRARIES_TABLE}")
    stripscript:print("}\")")

    stripscript:print("file(WRITE ${OUTPUT_FILE} ${_content})")

    stripscript:close()

    -- run strip-genex script
    local infopath = path.join(builddir, "main-info.txt")
    try {
        function()
            return os.vrunv(cmake.program,
                {
                    "-DINPUT_FILE=" .. path.join(builddir, "main-info.cmake"),
                    "-DOUTPUT_FILE=" .. infopath,
                    "-P",
                    stripscriptpath,
                },
                {
                    curdir = workdir
                }
            )
        end
    }

    -- get main-info.txt
    local info = io.load(infopath)
    local includedirs = info.INCLUDE_DIRS
    local linkdirs    = info.LINK_DIRS
    local defines     = info.COMPILE_DEFINITIONS
    local flags       = info.COMPILE_OPTIONS
    local ldflags     = info.LINK_OPTIONS
    local links       = nil
    local libfiles    = nil

    -- get CMakeCache.txt
    local is_msvc = false
    for line in io.lines(path.join(builddir, "CMakeCache.txt")) do
        if line:startswith("CMAKE_CXX_COMPILER") then
            local compiler = line:sub(line:find("=") + 1):trim()
            if path.basename(compiler):lower() == "cl" then
                is_msvc = true
            end
            break
        end
    end

    -- get build.ninja
    local ninjafile = path.join(builddir, "build.ninja")
    local ninjabuilds = nil
    if os.isfile(ninjafile) then
        local ninjadata = io.readfile(ninjafile)
        if ninjadata then
            if option.get("diagnosis") then
                cprint("finding links from %s\n${dim}%s", ninjafile, ninjadata)
            end

            local results = {}
            local current_build = nil
            local current_vars = nil
            for _, line in ipairs(ninjadata:split("\n")) do
                -- https://ninja-build.org/manual.html#_build_statements
                -- match build statement
                -- e.g.
                --      build CMakeFiles/main.dir/main.cpp.obj: ...
                --      build main.exe: ...
                local buildfiles = line:match("^build%s+([^:]+):")
                if buildfiles then
                    -- save previous statement if exists
                    if current_build and current_vars then
                        table.insert(results, { build = current_build, vars = current_vars })
                    end

                    local buildfile = os.argv(buildfiles)[1]
                    local basename = path.basename(buildfile)
                    if basename == "main" or basename == "libmain" or basename == "main.cpp" then
                        -- save current statement
                        current_build = buildfile
                        current_vars = {}
                    else
                        -- ignore unrelated build statements
                        current_build = nil
                        current_vars = nil
                    end
                elseif current_build then
                    -- match variable assignments
                    -- e.g.
                    --      ^  CONFIG = Debug
                    --      ^  DEFINES = -DXXX=YYY
                    --      ^  INCLUDES = -isystem /path/to/include
                    local key, value = line:match("^%s+([%w_]+)%s*=%s*(.+)$")
                    if key and value then
                        -- save current variable
                        current_vars[key] = value
                    elseif line == "" then
                        -- encounter empty line, save current statement and start a new one
                        table.insert(results, { build = current_build, vars = current_vars })
                        current_build = nil
                        current_vars = nil
                    end
                end
            end

            -- save the last statement if exists
            if current_build and current_vars then
                table.insert(results, { build = current_build, vars = current_vars })
            end
            
            ninjabuilds = results
        end
    end

    if ninjabuilds then
        local ninja_defines = {}
        local ninja_includes = {}
        local ninja_flags = {}
        local ninja_links = {}
        local ninja_linkdirs = {}
        local ninja_linkflags = {}

        -- strip command line prefix
        for _, builditem in pairs(ninjabuilds) do
            for key, value in pairs(builditem.vars) do
                if key == "DEFINES" then
                    -- strip -D, /D
                    for _, flag in ipairs(os.argv(value)) do
                        local define = flag:match("^-D(.+)$") or (is_msvc and flag:match("^/D(.+)$"))
                        if define and not _should_exclude(define) then
                            table.insert(ninja_defines, define)
                        end
                    end
                elseif key == "INCLUDES" then
                    local has_include = false
                    for _, flag in ipairs(os.argv(value)) do
                        if has_include then
                            local includedir = flag
                            table.insert(ninja_includes, includedir)
                            has_include = false
                        elseif flag == "-isystem" or flag == "-idirafter" or flag == "-I" or (is_msvc and flag == "/I") then
                            has_include = true
                        else
                            -- strip -I, /I, -external:I, /external:I
                            local includedir = flag:match("^-I(.+)$") or (
                                is_msvc and (
                                    flag:match("^/I(.+)$") or
                                    flag:match("^-external:I(.+)$") or
                                    flag:match("^/external:I(.+)$")
                                )
                            )
                            if includedir then
                                table.insert(ninja_includes, includedir)
                            end
                        end
                    end
                elseif key == "FLAGS" then
                    ninja_flags = table.join(ninja_flags, os.argv(value))
                elseif key == "LINK_LIBRARIES" then
                    for _, flag in ipairs(os.argv(value)) do
                        -- strip -l
                        if flag:startswith("-l") then
                            if #flag > 2 then
                                local link = flag:sub(3):trim()
                                table.insert(ninja_links, link)
                            end
                        else
                            table.insert(ninja_links, flag)
                        end
                    end
               
                elseif key == "LINK_PATH" then
                    for _, flag in ipairs(os.argv(value)) do
                        -- strip -L, /LIBPATH, /libpath, -LIBPATH, -libpath
                        local linkdir
                        if is_msvc then
                            linkdir = flag:match("^/LIBPATH:(.+)$") or
                                flag:match("^/libpath:(.+)$") or
                                flag:match("^-LIBPATH:(.+)$") or
                                flag:match("^-libpath:(.+)$")
                        else
                            linkdir = flag:match("^-L(.+)$")
                        end
                        if linkdir then
                            table.insert(ninja_linkdirs, linkdir)
                        end
                    end
                elseif key == "LINK_FLAGS" then
                    ninja_linkflags = table.join(ninja_linkflags, os.argv(value))
                end
            end
        end

        if #ninja_links > 0 then
            links = ninja_links
            libfiles = links
        end
        if #ninja_flags >0 and not ldflags then
            ldflags = ninja_linkflags
        end
        if #ninja_linkdirs >0 and not linkdirs then
            linkdirs = ninja_linkdirs
        end
        if #ninja_defines >0 and not defines then
            defines = ninja_defines
        end
        if #ninja_flags >0 and not flags then
            flags = ninja_flags
        end
        if #ninja_includes >0 and not includedirs then
            includedirs = ninja_includes
        end
    end

    -- remove work directory
    os.tryrm(workdir)

    -- get results
    if links or includedirs then
        local results = {}
        results.links       = table.reverse_unique(links)
        results.ldflags     = table.reverse_unique(ldflags)
        results.linkdirs    = table.unique(linkdirs)
        results.defines     = table.unique(defines)
        results.libfiles    = table.unique(libfiles)
        results.flags       = table.unique(flags)
        results.includedirs = table.unique(includedirs)
        return results
    end
end

-- find package using the cmake package manager
--
-- e.g.
--
-- find_package("cmake::ZLIB")
-- find_package("cmake::OpenCV", {require_version = "4.1.1"})
-- find_package("cmake::Boost", {configs = {components = {"regex", "system"}, presets = {Boost_USE_STATIC_LIB = true}}})
-- find_package("cmake::Foo", {configs = {moduledirs = "xxx"}})
--
-- we can use add_requires with {system = true}
--
-- add_requires("cmake::ZLIB", {system = true})
-- add_requires("cmake::OpenCV 4.1.1", {system = true})
-- add_requires("cmake::Boost", {configs = {components = {"regex", "system"}, presets = {Boost_USE_STATIC_LIB = true}}})
-- add_requires("cmake::Foo", {configs = {moduledirs = "xxx"}})
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, require_version = "1.0",
--                                 configs = {
--                                      components = {"regex", "system"},
--                                      moduledirs = "xxx",
--                                      presets = {
--                                          Boost_USE_STATIC_LIB = true
--                                      },
--                                      envs = {
--                                           CMAKE_PREFIX_PATH = "xxx",
--                                      },
--                                      find_script = "find_package(Foo CONFIG REQUIRED)",
--                                      link_script = "target_link_libraries(${PROJECT_NAME} PRIVATE Foo::Foo)",
--                                      target_type = "shared",
--                                      win32 = true
--                                 }}
--
function main(name, opt)
    opt = opt or {}
    local cmake = find_tool("cmake", {version = true})
    if not cmake then
        return
    end
    return _find_package(cmake, name, opt)
end
