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
-- @file        cpu.lua
--

-- define module
local cpu = cpu or {}

-- load modules
local os    = require("base/os")
local winos = require("base/winos")
local io    = require("base/io")

-- get cpu micro architecture for Intel
--
-- @see https://en.wikipedia.org/wiki/List_of_Intel_CPU_microarchitectures
-- http://www.intel.com/content/www/us/en/processors/architectures-software-developer-manuals.html
-- https://github.com/tesseract-ocr/tesseract/blob/master/cmake/OptimizeForArchitecture.cmake
--
function cpu._march_intel()
    local maps = {}
    local cpu_family = cpu.family()
    local cpu_model  = cpu.model()
    if cpu_family == 6 then
        maps[0x0E] = "core"
        maps[0x0F] = "merom"
        maps[0x17] = "penryn"
        maps[0x1D] = "penryn"
        maps[0x1A] = "nehalem"
        maps[0x1C] = "atom"
        maps[0x1E] = "nehalem"
        maps[0x1F] = "nehalem"
        maps[0x25] = "westmere"
        maps[0x2A] = "sandy-bridge"
        maps[0x2C] = "westmere"
        maps[0x2D] = "sandy-bridge"
        maps[0x2E] = "nehalem"
        maps[0x2F] = "westmere"
        maps[0x3A] = "ivy-bridge"
        maps[0x3C] = "haswell"
        maps[0x3D] = "broadwell"
        maps[0x3E] = "ivy-bridge"
        maps[0x3F] = "haswell"
        maps[0x45] = "haswell"
        maps[0x46] = "haswell"
        maps[0x47] = "broadwell"
        maps[0x4c] = "silvermont"
        maps[0x4E] = "skylake"
        maps[0x4F] = "broadwell"
        maps[0x55] = "skylake-avx512"
        maps[0x56] = "broadwell"
        maps[0x57] = "knights-landing"
        maps[0x5a] = "silvermont"
        maps[0x5c] = "goldmont"
        maps[0x5E] = "skylake"
        maps[0x66] = "cannonlake"
        maps[0x8E] = "kaby-lake"
        maps[0x9E] = "kaby-lake"
    elseif cpu_family == 7 then
        -- TODO Itanium
    elseif cpu_family == 15 then
        -- TODO NetBurst
    end
    return cpu_model and maps[cpu_model]
end

-- get cpu micro architecture for AMD
--
-- @see https://en.wikipedia.org/wiki/List_of_AMD_CPU_microarchitectures
--
function cpu._march_amd()
    local cpu_family = cpu.family()
    local cpu_model  = cpu.model()
    if cpu_family == 23 then
        return "zen"
    elseif cpu_family == 22 then
        return "AMD 16h"
    elseif cpu_family == 21 then
        if cpu_model < 2 then
            return "bulldozer"
        else
            return "piledriver"
        end
    elseif cpu_family == 20 then
        return "AMD 14h"
    elseif cpu_family == 16 then
        return "barcelona"
    elseif cpu_family == 15 then
        if cpu_model > 64 then
            return "k8-sse3"
        else
            return "k8"
        end
    end
end

-- get cpu info
function cpu._info()
    local cpuinfo = cpu._CPUINFO
    if cpuinfo == nil then
        cpuinfo = {}
        if os.host() == "macosx" then
            local ok, sysctl_result = os.iorun("/usr/sbin/sysctl -n machdep.cpu.vendor machdep.cpu.model machdep.cpu.family machdep.cpu.features")
            if ok and sysctl_result then
                sysctl_result = sysctl_result:trim():split('\n', {plain = true})
                cpuinfo.vendor_id  = sysctl_result[1]
                cpuinfo.cpu_model  = sysctl_result[2]
                cpuinfo.cpu_family = sysctl_result[3]
                cpuinfo.cpu_flags  = sysctl_result[4]
                if cpuinfo.cpu_flags then
                    cpuinfo.cpu_flags = cpuinfo.cpu_flags:lower():gsub("%.", "_")
                end
            end
        elseif os.host() == "linux" then
            -- FIXME
            -- local proc_cpuinfo = io.readfile("/proc/cpuinfo")
            local ok, proc_cpuinfo = os.iorun("cat /proc/cpuinfo")
            if ok and proc_cpuinfo then
                for _, line in ipairs(proc_cpuinfo:split('\n', {plain = true})) do
                    if not cpuinfo.vendor_id and line:startswith("vendor_id") then
                        cpuinfo.vendor_id = line:match("vendor_id%s+:%s+(.*)")
                    end
                    if not cpuinfo.cpu_model and line:startswith("model") then
                        cpuinfo.cpu_model = line:match("model%s+:%s+(.*)")
                    end
                    if not cpuinfo.cpu_family and line:startswith("cpu family") then
                        cpuinfo.cpu_family = line:match("cpu family%s+:%s+(.*)")
                    end
                    if not cpuinfo.cpu_flags and line:startswith("flags") then
                        cpuinfo.cpu_flags = line:match("flags%s+:%s+(.*)")
                    end
                end
            end
        elseif os.host() == "windows" then
            cpuinfo.vendor_id  = winos.registry_query("HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0;VendorIdentifier")
            local cpu_id = winos.registry_query("HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0;Identifier")
            if cpu_id then
                local cpu_family, cpu_model = cpu_id:match("Family (%d+) Model (%d+)")
                cpuinfo.cpu_family = cpu_family
                cpuinfo.cpu_model  = cpu_model
            end
        end
        cpu._CPUINFO = cpuinfo
    end
    return cpuinfo
end

-- get vendor id
function cpu.vendor()
    return cpu._info().vendor_id
end

-- get cpu model
function cpu.model()
    local cpu_model = cpu._info().cpu_model
    return cpu_model and tonumber(cpu_model)
end

-- get cpu family
function cpu.family()
    local cpu_family = cpu._info().cpu_family
    return cpu_family and tonumber(cpu_family)
end

-- get cpu micro architecture
function cpu.march()
    local march = cpu._MARCH
    if march == nil then
        local cpu_vendor = cpu.vendor()
        if cpu_vendor == "GenuineIntel" then
            march = cpu._march_intel()
        elseif cpu_vendor == "AuthenticAMD" then
            march = cpu._march_amd()
        end
        cpu._MARCH = march
    end
    return march
end

-- get cpu number
function cpu.number()
    return os.cpuinfo().ncpu
end

-- get cpu info
function cpu.info()
    local cpuinfo = {}
    cpuinfo.vendor = cpu.vendor()
    cpuinfo.model  = cpu.model()
    cpuinfo.family = cpu.family()
    cpuinfo.march  = cpu.march()
    cpuinfo.number = cpu.number()
    return cpuinfo
end

-- return module
return cpu
