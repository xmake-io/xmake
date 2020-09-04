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

-- get configs
function _get_configs(package, configs)
    local configs = configs or {}
    if package:is_plat("windows") then
        local vs_runtime = package:config("vs_runtime")
        if vs_runtime then
            table.insert(configs, '-DCMAKE_CXX_FLAGS_DEBUG="/' .. vs_runtime .. 'd"')
            table.insert(configs, '-DCMAKE_CXX_FLAGS_RELEASE="/' .. vs_runtime .. '"')
            table.insert(configs, '-DCMAKE_C_FLAGS_DEBUG="/' .. vs_runtime .. 'd"')
            table.insert(configs, '-DCMAKE_C_FLAGS_RELEASE="/' .. vs_runtime .. '"')
        end
    elseif package:is_plat("android") then
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

