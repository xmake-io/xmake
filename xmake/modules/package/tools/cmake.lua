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
-- @file        cmake.lua
--

-- imports
import("core.base.option")
import("core.tool.toolchain")
import("lib.detect.find_file")
import("lib.detect.find_tool")

-- get configs for windows
function _get_configs_for_windows(package, configs)
    if package:is_arch("x64") then
        table.insert(configs, "-A")
        table.insert(configs, "x64")
    end
    local vs_runtime = package:config("vs_runtime")
    if vs_runtime then
        table.insert(configs, '-DCMAKE_CXX_FLAGS_DEBUG="/' .. vs_runtime .. 'd"')
        table.insert(configs, '-DCMAKE_CXX_FLAGS_RELEASE="/' .. vs_runtime .. '"')
        table.insert(configs, '-DCMAKE_C_FLAGS_DEBUG="/' .. vs_runtime .. 'd"')
        table.insert(configs, '-DCMAKE_C_FLAGS_RELEASE="/' .. vs_runtime .. '"')
    end
end

-- get configs for android
function _get_configs_for_android(package, configs)

    -- https://developer.android.google.cn/ndk/guides/cmake
    local ndk = get_config("ndk")
    if ndk and os.isdir(ndk) then
        local ndk_sdkver = get_config("ndk_sdkver")
        local ndk_cxxstl = get_config("ndk_cxxstl")
        table.insert(configs, "-DCMAKE_TOOLCHAIN_FILE=" .. path.join(ndk, "build/cmake/android.toolchain.cmake"))
        table.insert(configs, "-DANDROID_ABI=" .. package:arch())
        if ndk_sdkver then
            table.insert(configs, "-DANDROID_NATIVE_API_LEVEL=" .. ndk_sdkver)
        end
        if ndk_cxxstl then
            table.insert(configs, "-DANDROID_STL=" .. ndk_cxxstl)
        end
    end
end

-- get configs for iphoneos
function _get_configs_for_iphoneos(package, configs)
    local envs                     = {}
    local cflags                   = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cflags"))
    local cxxflags                 = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cxxflags"))
    envs.CMAKE_C_FLAGS             = table.concat(cflags, ' ')
    envs.CMAKE_CXX_FLAGS           = table.concat(cxxflags, ' ')
    envs.CMAKE_ASM_FLAGS           = table.concat(table.wrap(package:build_getenv("asflags")), ' ')
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = table.concat(table.wrap(package:build_getenv("ldflags")), ' ')
    envs.CMAKE_SHARED_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("shflags")), ' ')
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "ONLY"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "ONLY"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM = "NEVER"
    for k, v in pairs(envs) do
        table.insert(configs, "-D" .. k .. "=" .. v)
    end
end

-- get configs for mingw
function _get_configs_for_mingw(package, configs)
    local envs                     = {}
    local cflags                   = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cflags"))
    local cxxflags                 = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cxxflags"))
    local sdkdir                   = package:build_getenv("mingw") or package:build_getenv("sdk")
    envs.CMAKE_C_COMPILER          = package:build_getenv("cc")
    envs.CMAKE_CXX_COMPILER        = package:build_getenv("cxx")
    envs.CMAKE_ASM_COMPILER        = package:build_getenv("as")
    envs.CMAKE_AR                  = package:build_getenv("ar")
    envs.CMAKE_LINKER              = package:build_getenv("ld")
    envs.CMAKE_RANLIB              = package:build_getenv("ranlib")
    envs.CMAKE_C_FLAGS             = table.concat(cflags, ' ')
    envs.CMAKE_CXX_FLAGS           = table.concat(cxxflags, ' ')
    envs.CMAKE_ASM_FLAGS           = table.concat(table.wrap(package:build_getenv("asflags")), ' ')
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = table.concat(table.wrap(package:build_getenv("ldflags")), ' ')
    envs.CMAKE_SHARED_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("shflags")), ' ')
    envs.CMAKE_SYSTEM_NAME         = "Windows"
    -- avoid find and add system include/library path
    envs.CMAKE_FIND_ROOT_PATH      = sdkdir
    envs.CMAKE_SYSROOT             = sdkdir
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "ONLY"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "ONLY"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM = "NEVER"
    -- avoid add -isysroot on macOS
    envs.CMAKE_OSX_SYSROOT = ""
    -- Avoid cmake to add the flags -search_paths_first and -headerpad_max_install_names on macOS
    envs.HAVE_FLAG_SEARCH_PATHS_FIRST = "0"
    for k, v in pairs(envs) do
        table.insert(configs, "-D" .. k .. "=" .. v)
    end
end

-- get configs for cross
function _get_configs_for_cross(package, configs)
    local envs                     = {}
    local cflags                   = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cflags"))
    local cxxflags                 = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cxxflags"))
    local sdkdir                   = package:build_getenv("sdk")
    envs.CMAKE_C_COMPILER          = package:build_getenv("cc")
    envs.CMAKE_CXX_COMPILER        = package:build_getenv("cxx")
    envs.CMAKE_ASM_COMPILER        = package:build_getenv("as")
    envs.CMAKE_AR                  = package:build_getenv("ar")
    envs.CMAKE_LINKER              = package:build_getenv("ld")
    envs.CMAKE_RANLIB              = package:build_getenv("ranlib")
    envs.CMAKE_C_FLAGS             = table.concat(cflags, ' ')
    envs.CMAKE_CXX_FLAGS           = table.concat(cxxflags, ' ')
    envs.CMAKE_ASM_FLAGS           = table.concat(table.wrap(package:build_getenv("asflags")), ' ')
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = table.concat(table.wrap(package:build_getenv("ldflags")), ' ')
    envs.CMAKE_SHARED_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("shflags")), ' ')
    envs.CMAKE_SYSTEM_NAME         = "Linux"
    -- avoid find and add system include/library path
    envs.CMAKE_FIND_ROOT_PATH      = sdkdir
    envs.CMAKE_SYSROOT             = sdkdir
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "ONLY"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "ONLY"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM = "NEVER"
    -- avoid add -isysroot on macOS
    envs.CMAKE_OSX_SYSROOT = ""
    -- Avoid cmake to add the flags -search_paths_first and -headerpad_max_install_names on macOS
    envs.HAVE_FLAG_SEARCH_PATHS_FIRST = "0"
    for k, v in pairs(envs) do
        table.insert(configs, "-D" .. k .. "=" .. v)
    end
end

-- get configs
function _get_configs(package, configs)
    local configs = configs or {}
    if package:is_plat("windows") then
        _get_configs_for_windows(package, configs)
    elseif package:is_plat("android") then
        _get_configs_for_android(package, configs)
    elseif package:is_plat("iphoneos") then
        _get_configs_for_iphoneos(package, configs)
    elseif package:is_plat("mingw") then
        _get_configs_for_mingw(package, configs)
    elseif not package:is_plat(os.subhost()) then
        _get_configs_for_cross(package, configs)
    end
    local cflags = package:config("cflags")
    if cflags then
        table.insert(configs, '-DCMAKE_C_FLAGS="' .. cflags .. '"')
    end
    local cxflags = package:config("cxflags")
    if cxflags then
        table.insert(configs, '-DCMAKE_C_FLAGS="' .. cxflags .. '"')
        table.insert(configs, '-DCMAKE_CXX_FLAGS="' .. cxflags .. '"')
    end
    local cxxflags = package:config("cxxflags")
    if cxxflags then
        table.insert(configs, '-DCMAKE_CXX_FLAGS="' .. cxxflags .. '"')
    end
    local asflags = package:config("asflags")
    if asflags then
        table.insert(configs, '-DCMAKE_ASM_FLAGS="' .. asflags .. '"')
    end
    return configs
end

-- get build environments
function buildenvs(package)
    local envs               = {}
    local CMAKE_LIBRARY_PATH = {}
    local CMAKE_INCLUDE_PATH = {}
    local CMAKE_PREFIX_PATH  = {}
    for _, dep in ipairs(package:orderdeps()) do
        if dep:isSys() then
            local fetchinfo = dep:fetch()
            if fetchinfo then
                table.join2(CMAKE_LIBRARY_PATH, fetchinfo.linkdirs)
                table.join2(CMAKE_INCLUDE_PATH, fetchinfo.includedirs)
            end
        else
            table.join2(CMAKE_PREFIX_PATH, dep:installdir())
        end
    end
    envs.CMAKE_LIBRARY_PATH = path.joinenv(CMAKE_LIBRARY_PATH)
    envs.CMAKE_INCLUDE_PATH = path.joinenv(CMAKE_INCLUDE_PATH)
    envs.CMAKE_PREFIX_PATH  = path.joinenv(CMAKE_PREFIX_PATH)
    return envs
end

-- build package
function build(package, configs, opt)

    -- init options
    opt = opt or {}

    -- enter build directory
    local buildir = opt.buildir or "build_" .. hash.uuid4():split('%-')[1]
    os.mkdir(path.join(buildir, "install"))
    local oldir = os.cd(buildir)

    -- init arguments
    --
    -- @see https://cmake.org/cmake/help/v3.14/module/GNUInstallDirs.html
    -- LIBDIR: object code libraries (lib or lib64 or lib/<multiarch-tuple> on Debian)
    -- 
    local argv = {"-DCMAKE_INSTALL_PREFIX=" .. path.absolute("install"), "-DCMAKE_INSTALL_LIBDIR=" .. path.absolute("install/lib")}

    -- pass configurations
    for name, value in pairs(_get_configs(package, configs)) do
        value = tostring(value):trim()
        if type(name) == "number" then
            if value ~= "" then
                table.insert(argv, value)
            end
        else
            table.insert(argv, "--" .. name .. "=" .. value)
        end
    end
    table.insert(argv, '..')

    -- do build 
    os.vrunv("cmake", argv, {envs = opt.envs or buildenvs(package)})
    os.vrunv("cmake", {"--build", "."}, {envs = opt.envs or buildenvs(package)})
    os.cd(oldir)
end

-- install package
function install(package, configs, opt)

    -- init options
    opt = opt or {}

    -- enter build directory
    local buildir = opt.buildir or "build_" .. hash.uuid4():split('%-')[1]
    os.mkdir(path.join(buildir, "install"))
    local oldir = os.cd(buildir)

    -- init arguments
    --
    -- @see https://cmake.org/cmake/help/v3.14/module/GNUInstallDirs.html
    -- LIBDIR: object code libraries (lib or lib64 or lib/<multiarch-tuple> on Debian)
    -- 
    local argv = {"-DCMAKE_INSTALL_PREFIX=" .. path.absolute("install"), "-DCMAKE_INSTALL_LIBDIR=" .. path.absolute("install/lib")}
    if package:is_plat("windows") and package:is_arch("x64") then
        table.insert(argv, "-A")
        table.insert(argv, "x64")
    end

    -- pass configurations
    for name, value in pairs(_get_configs(package, configs)) do
        value = tostring(value):trim()
        if type(name) == "number" then
            if value ~= "" then
                table.insert(argv, value)
            end
        else
            table.insert(argv, "--" .. name .. "=" .. value)
        end
    end
    table.insert(argv, '..')

    -- generate build file
    os.vrunv("cmake", argv, {envs = opt.envs or buildenvs(package)})

    -- do build and install
    if package:is_plat("windows") then
        local slnfile = assert(find_file("*.sln", os.curdir()), "*.sln file not found!")
        local runenvs = toolchain.load("msvc", {plat = package:plat(), arch = package:arch()}):runenvs()
        local msbuild = find_tool("msbuild", {envs = runenvs})
        os.vrunv(msbuild.program, {slnfile, "-nologo", "-t:Rebuild", "-p:Configuration=" .. (package:debug() and "Debug" or "Release"), "-p:Platform=" .. (package:is_arch("x64") and "x64" or "Win32")}, {envs = runenvs})
        local projfile = os.isfile("INSTALL.vcxproj") and "INSTALL.vcxproj" or "INSTALL.vcproj"
        if os.isfile(projfile) then
            os.vrunv(msbuild.program, {projfile, "/property:configuration=" .. (package:debug() and "Debug" or "Release")}, {envs = runenvs})
            os.trycp("install/lib", package:installdir()) -- perhaps only headers library
            os.trycp("install/include", package:installdir())
        else
            os.cp("**.lib", package:installdir("lib"))
            os.cp("**.dll", package:installdir("lib"))
            os.cp("**.exp", package:installdir("lib"))
        end
    else
        local njob = tostring(math.ceil(os.cpuinfo().ncpu * 3 / 2))
        argv = {"-j" .. njob}
        if option.get("verbose") then
            table.insert(argv, "VERBOSE=1")
        end
        if is_host("bsd") then
            os.vrunv("gmake", argv)
            os.vrunv("gmake", {"install"})
        else
            os.vrunv("make", argv)
            os.vrunv("make", {"install"})
        end
        os.trycp("install/lib", package:installdir())
        os.trycp("install/include", package:installdir())
    end
    os.cd(oldir)
end

