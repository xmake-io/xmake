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
local os      = require("base/os")
local winos   = require("base/winos")
local io      = require("base/io")
local hashset = require("base/hashset")

-- get cpu micro architecture for Intel
--
-- @see https://en.wikichip.org/wiki/intel/cpuid
-- https://github.com/xmake-io/xmake/issues/1120
--
function cpu._march_intel()
    local cpu_family = cpu.family()
    local cpu_model  = cpu.model()
    if cpu_family == 3 then
        return "80386"
    elseif cpu_family == 4 then
        if cpu_model >= 1 and cpu_model <= 9 then
            return "80486"
        end
    elseif cpu_family == 5 then
        if cpu_model == 9 or cpu_model == 10 then
            return "Lakemont"
        elseif cpu_model == 1 or cpu_model == 2 or
                cpu_model == 4 or cpu_model == 7 or cpu_model == 8 then
            return "P5"
        end
    elseif cpu_family == 6 then
        -- mic architecture
        if cpu_model == 133 then
            return "Knights Mill"
        elseif cpu_model == 87 then
            return "Knights Landing"
        end

        -- small cores
        if cpu_model == 134 then
            return "Tremont"
        elseif cpu_model == 122 then
            return "Goldmont Plus"
        elseif cpu_model == 95 or cpu_model == 92 then
            return "Goldmont"
        elseif cpu_model == 76 then
            return "Airmont"
        elseif cpu_model == 93 or cpu_model == 90 or
                cpu_model == 77 or cpu_model == 74 or cpu_model == 55 then
            return "Silvermont"
        elseif cpu_model == 54 or cpu_model == 53 or cpu_model == 39 then
            return "Saltwell"
        elseif cpu_model == 38 or cpu_model == 28 then
            return "Bonnell"
        end

        -- big cores
        if cpu_model == 183 then
            return "Raptor Lake"
        elseif cpu_model == 151 or cpu_model == 154 then
            return "Alder Lake"
        elseif cpu_model == 167 then
            return "Rocket Lake"
        elseif cpu_model == 140 then
            return "Tiger Lake"
        elseif cpu_model == 126 or cpu_model == 125 then
            return "Ice Lake"
        elseif cpu_model == 165 then
            return "Comet Lake"
        elseif cpu_model == 102 then
            return "Cannon Lake"
        elseif cpu_model == 142 or cpu_model == 158 then
            return "Kaby Lake"
        elseif cpu_model == 94 or cpu_model == 78 or cpu_model == 85 then
            return "Skylake"
        elseif cpu_model == 71 or cpu_model == 61 or cpu_model == 79 or cpu_model == 86 then
            return "Broadwell"
        elseif cpu_model == 70 or cpu_model == 69 or cpu_model == 60 or cpu_model == 63 then
            return "Haswell"
        elseif cpu_model == 58 or cpu_model == 62 then
            return "Ivy Bridge"
        elseif cpu_model == 42 or cpu_model == 45 then
            return "Sandy Bridge"
        elseif cpu_model == 37 or cpu_model == 44 or cpu_model == 47 then
            return "Westmere"
        elseif cpu_model == 31 or cpu_model == 30 or cpu_model == 46 or cpu_model == 26 then
            return "Nehalem"
        elseif cpu_model == 23 or cpu_model == 29 then
            return "Penryn"
        elseif cpu_model == 22 or cpu_model == 15 then
            return "Core"
        elseif cpu_model == 14 then
            return "Modified Pentium M"
        elseif cpu_model == 21 or cpu_model == 13 or cpu_model == 9 then
            return "Pentium M"
        elseif cpu_model == 11 or cpu_model == 10 or cpu_model == 8 or cpu_model == 7 or
                cpu_model == 6 or cpu_model == 5 or cpu_model == 1 then
            return "P6"
        end
    elseif cpu_family == 7 then
        -- TODO Itanium
    elseif cpu_family == 11 then
        if cpu_model == 0 then
            return "knights-ferry"
        elseif cpu_model == 1 then
            return "knights-corner"
        end
    elseif cpu_family == 15 then
        if cpu_model <= 6 then
            return "netburst"
        end
    end
end

-- get cpu micro architecture for AMD
--
-- @see https://en.wikichip.org/wiki/amd/cpuid
--
function cpu._march_amd()
    local cpu_family = cpu.family()
    local cpu_model  = cpu.model()
    if cpu_family == 25 then
        return "Zen 3"
    elseif cpu_family == 24 then
        return "Zen"
    elseif cpu_family == 23 then
        if cpu_model == 144 or cpu_model == 113 or cpu_model == 96 or cpu_model == 49 then
            return "Zen 2"
        elseif cpu_model == 24 or cpu_model == 8 then
            return "Zen+"
        else
            return "Zen"
        end
    elseif cpu_family == 22 then
        return "AMD 16h"
    elseif cpu_family == 21 then
        if cpu_model < 2 then
            return "Bulldozer"
        else
            -- TODO and Steamroller, Excavator ..
            return "Piledriver"
        end
    elseif cpu_family == 20 then
        return "Bobcat"
    elseif cpu_family == 16 then
        return "K10"
    elseif cpu_family == 15 then
        if cpu_model > 64 then
            return "K8-sse3"
        else
            return "K8"
        end
    end
end

-- get cpu info
function cpu._info()
    local cpuinfo = cpu._CPUINFO
    if cpuinfo == nil then
        cpuinfo = {}
        if os.host() == "macosx" then
            local ok, sysctl_result = os.iorun("/usr/sbin/sysctl -n machdep.cpu.vendor machdep.cpu.model machdep.cpu.family machdep.cpu.features machdep.cpu.brand_string")
            if ok and sysctl_result then
                sysctl_result = sysctl_result:trim():split('\n', {plain = true})
                cpuinfo.vendor_id      = sysctl_result[1]
                cpuinfo.cpu_model      = sysctl_result[2]
                cpuinfo.cpu_family     = sysctl_result[3]
                cpuinfo.cpu_features   = sysctl_result[4]
                if cpuinfo.cpu_features then
                    cpuinfo.cpu_features = cpuinfo.cpu_features:lower():gsub("%.", "_")
                end
                cpuinfo.cpu_model_name = sysctl_result[5]
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
                    if not cpuinfo.cpu_model_name and line:startswith("model name") then
                        cpuinfo.cpu_model_name = line:match("model name%s+:%s+(.*)")
                    end
                    if not cpuinfo.cpu_family and line:startswith("cpu family") then
                        cpuinfo.cpu_family = line:match("cpu family%s+:%s+(.*)")
                    end
                    if not cpuinfo.cpu_features and line:startswith("flags") then
                        cpuinfo.cpu_features = line:match("flags%s+:%s+(.*)")
                    end
                    -- termux on android
                    if not cpuinfo.cpu_features and line:startswith("Features") then
                        cpuinfo.cpu_features = line:match("Features%s+:%s+(.*)")
                    end
                end
            end
        elseif os.host() == "windows" then
            cpuinfo.vendor_id      = winos.registry_query("HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0;VendorIdentifier")
            cpuinfo.cpu_model_name = winos.registry_query("HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0;ProcessorNameString")
            local cpu_id = winos.registry_query("HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0;Identifier")
            if cpu_id then
                local cpu_family, cpu_model = cpu_id:match("Family (%d+) Model (%d+)")
                cpuinfo.cpu_family = cpu_family
                cpuinfo.cpu_model  = cpu_model
            end
        elseif os.host() == "bsd" then
            local ok, dmesginfo = os.iorun("dmesg")
            if ok and dmesginfo then
                for _, line in ipairs(dmesginfo:split('\n', {plain = true})) do
                    if not cpuinfo.vendor_id and line:find("Origin=", 1, true) then
                        cpuinfo.vendor_id = line:match("Origin=\"(.-)\"")
                    end
                    if not cpuinfo.cpu_model and line:find("Model=", 1, true) then
                        cpuinfo.cpu_model = line:match("Model=([%d%w]+)")
                    end
                    if not cpuinfo.cpu_family and line:find("Family=", 1, true) then
                        cpuinfo.cpu_family = line:match("Family=([%d%w]+)")
                    end
                    if line:find("Features=", 1, true) then
                        local cpu_features = line:match("Features=.*<(.-)>")
                        if cpu_features then
                            if cpuinfo.cpu_features then
                                cpuinfo.cpu_features = cpuinfo.cpu_features .. "," .. cpu_features
                            else
                                cpuinfo.cpu_features = cpu_features
                            end
                        end
                    end
                end
                if cpuinfo.cpu_features then
                    cpuinfo.cpu_features = cpuinfo.cpu_features:lower():gsub(",", " ")
                end
                local ok, cpu_model_name = os.iorun("sysctl -n hw.model")
                if ok and cpu_model_name then
                    cpuinfo.cpu_model_name = cpu_model_name:trim()
                end
            end
        end
        cpu._CPUINFO = cpuinfo
    end
    return cpuinfo
end

-- get cpu stats info
function cpu._statinfo(name)
    local stats = cpu._STATS
    local stime = cpu._STIME
    if stats == nil or stime == nil or os.time() - stime > 1 then -- cache 1s
        stats = os._cpuinfo()
        cpu._STATS = stats
        cpu._STIME = os.time()
    end
    if name then
        return stats[name]
    else
        return stats
    end
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

-- get cpu model name
function cpu.model_name()
    return cpu._info().cpu_model_name
end

-- get cpu family
function cpu.family()
    local cpu_family = cpu._info().cpu_family
    return cpu_family and tonumber(cpu_family)
end

-- get cpu features
function cpu.features()
    return cpu._info().cpu_features
end

-- has the given feature?
function cpu.has_feature(name)
    local features = cpu._FEATURES
    if not features then
        features = cpu.features()
        if features then
            features = hashset.from(features:split('%s'))
        end
        cpu._FEATURES = features
    end
    return features:has(name)
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
    return cpu._statinfo("ncpu")
end

-- get cpu usage rate
function cpu.usagerate()
    return cpu._statinfo("usagerate")
end

-- get cpu info
function cpu.info(name)
    local cpuinfo = {}
    cpuinfo.vendor     = cpu.vendor()
    cpuinfo.model      = cpu.model()
    cpuinfo.family     = cpu.family()
    cpuinfo.march      = cpu.march()
    cpuinfo.ncpu       = cpu.number()
    cpuinfo.features   = cpu.features()
    cpuinfo.usagerate  = cpu.usagerate()
    cpuinfo.model_name = cpu.model_name()
    if name then
        return cpuinfo[name]
    else
        return cpuinfo
    end
end

-- return module
return cpu
