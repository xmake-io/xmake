--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
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
-- @file        cmake.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_file")

-- get configs
function _get_configs(package, configs)
    local configs = configs or {}
    if package:plat() == "windows" then
        local vs_runtime = package:config("vs_runtime")
        if vs_runtime then
            table.insert(configs, '-DCMAKE_CXX_FLAGS_DEBUG="/' .. vs_runtime .. 'd"')
            table.insert(configs, '-DCMAKE_CXX_FLAGS_RELEASE="/' .. vs_runtime .. '"')
            table.insert(configs, '-DCMAKE_C_FLAGS_DEBUG="/' .. vs_runtime .. 'd"')
            table.insert(configs, '-DCMAKE_C_FLAGS_RELEASE="/' .. vs_runtime .. '"')
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

-- enter environments
function _enter_envs(package)
    
    -- get old environments
    local envs = {}
    envs.CMAKE_PREFIX_PATH  = os.getenv("CMAKE_PREFIX_PATH")
    envs.CMAKE_INCLUDE_PATH = os.getenv("CMAKE_INCLUDE_PATH")
    envs.CMAKE_LIBRARY_PATH = os.getenv("CMAKE_LIBRARY_PATH")

    -- set new environments
    for _, dep in ipairs(package:orderdeps()) do
        if dep:isSys() then
            local fetchinfo = dep:fetch()
            if fetchinfo then
                os.addenv("CMAKE_LIBRARY_PATH", unpack(table.wrap(fetchinfo.linkdirs)))
                os.addenv("CMAKE_INCLUDE_PATH", unpack(table.wrap(fetchinfo.includedirs)))
            end
        else
            os.addenv("CMAKE_PREFIX_PATH", dep:installdir())
        end
    end
    return envs
end

-- leave environments
function _leave_envs(package, envs)
    for k, v in pairs(envs) do
        os.setenv(k, v)
    end
end

-- install package
function install(package, configs)

    -- enter build directory
    os.mkdir("build/install")
    local oldir = os.cd("build")

    -- init arguments
    local argv = {"-DCMAKE_INSTALL_PREFIX=" .. path.absolute("install")}
    if is_plat("windows") and is_arch("x64") then
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

    -- enter environments
    local envs = _enter_envs(package)

    -- generate build file
    os.vrunv("cmake", argv)

    -- do build and install
    if is_host("windows") then
        local slnfile = assert(find_file("*.sln", os.curdir()), "*.sln file not found!")
        os.vrun("msbuild \"%s\" -nologo -t:Rebuild -p:Configuration=%s -p:Platform=%s", slnfile, package:debug() and "Debug" or "Release", is_arch("x64") and "x64" or "Win32")
        local projfile = os.isfile("INSTALL.vcxproj") and "INSTALL.vcxproj" or "INSTALL.vcproj"
        if os.isfile(projfile) then
            os.vrun("msbuild \"%s\" /property:configuration=%s", projfile, package:debug() and "Debug" or "Release")
            os.cp("install/lib", package:installdir())
            os.cp("install/include", package:installdir())
        else
            os.cp("**.lib", package:installdir("lib"))
            os.cp("**.dll", package:installdir("lib"))
            os.cp("**.exp", package:installdir("lib"))
        end
    else
        os.vrun("make -j4")
        os.vrun("make install")
        os.cp("install/lib", package:installdir())
        os.cp("install/include", package:installdir())
    end

    -- leave environments
    _leave_envs(package, envs)
    os.cd(oldir)
end

