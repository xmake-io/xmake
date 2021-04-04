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

-- get cpu info
function cpu.info()
    local cpuinfo = cpu._CPUINFO
    if cpuinfo == nil then
        cpuinfo = {}
        if os.host() == "macosx" then
            local ok, sysctl_result = os.iorun("/usr/sbin/sysctl -n machdep.cpu.vendor machdep.cpu.model machdep.cpu.family machdep.cpu.features")
            if ok and sysctl_result then
                sysctl_result = sysctl_result:trim():split('\n', {plain = true})
                cpuinfo.vender_id  = sysctl_result[1]
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
                    if not cpuinfo.vender_id and line:startswith("vendor_id") then
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
            cpuinfo.vender_id  = winos.registry_query("HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0;VendorIdentifier")
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

-- return module
return cpu
