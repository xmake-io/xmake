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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.project.config")

-- get subsystem version defined value
function _winver_subsystem(winver)

    -- ignore the subname with '_xxx'
    winver = (winver or ""):split('_')[1]

    -- make defined values
    local defvals = 
    {
        win10   = "10.00" 
    ,   win81   = "6.03" 
    ,   winblue = "6.03"  
    ,   win8    = "6.02"
    ,   win7    = "6.01" 
    }
    return defvals[winver] or "10.00"
end

-- load for umdf driver
function driver_umdf(target)

    -- set kind
    target:set("kind", "shared")

    -- add links
    target:add("links", "ntdll", "OneCoreUAP", "mincore", "ucrt")
    target:add("shflags", "-NODEFAULTLIB:kernel32.lib", "-NODEFAULTLIB:user32.lib", "-NODEFAULTLIB:libucrt.lib", {force = true})

    -- add subsystem
    target:add("shflags", "-subsystem:windows," .. _winver_subsystem(winver), {force = true})

    -- set default driver entry if does not exist
    local entry = false
    for _, ldflag in ipairs(target:get("shflags")) do
        ldflag = ldflag:lower()
        if ldflag:find("[/%-]entry:") then
            entry = true
            break
        end
    end
    if not entry then
        target:add("links", "WdfDriverStubUm")
    end
end

-- load for kmdf driver
function driver_kmdf(target)

    -- set kind
    target:set("kind", "binary")

    -- set filename: xxx.sys
    target:set("filename", target:basename() .. ".sys")

    -- add links
    target:add("links", "BufferOverflowFastFailK", "ntoskrnl", "hal", "wmilib", "WdfLdr", "ntstrsafe", "wdmsec")

    -- compile as kernel driver
    target:add("cxflags", "-kernel", {force = true})
    target:add("ldflags", "-kernel", "-driver", {force = true})

    -- add subsystem    
    target:add("ldflags", "-subsystem:native," .. _winver_subsystem(winver), {force = true})

    -- set default driver entry if does not exist
    local entry = false
    for _, ldflag in ipairs(target:get("ldflags")) do
        ldflag = ldflag:lower()
        if ldflag:find("[/%-]entry:") then
            entry = true
            break
        end
    end
    if not entry then
        target:add("links", "WdfDriverEntry")
        target:add("ldflags", "-entry:FxDriverEntry" .. (is_arch("x86") and "@8" or ""), {force = true})
    end
end

-- load for wdm driver
function driver_wdm(target)

    -- set kind
    target:set("kind", "binary")

    -- set filename: xxx.sys
    target:set("filename", target:basename() .. ".sys")

    -- add links
    target:add("links", "BufferOverflowFastFailK", "ntoskrnl", "hal", "wmilib", "ntstrsafe")

    -- compile as kernel driver
    target:add("cxflags", "-kernel", {force = true})
    target:add("ldflags", "-kernel", "-driver", {force = true})

    -- add subsystem    
    target:add("ldflags", "-subsystem:native," .. _winver_subsystem(winver), {force = true})

    -- set default driver entry if does not exist
    local entry = false
    for _, ldflag in ipairs(target:get("ldflags")) do
        ldflag = ldflag:lower()
        if ldflag:find("[/%-]entry:") then
            entry = true
            break
        end
    end
    if not entry then
        target:add("ldflags", "-entry:GsDriverEntry" .. (is_arch("x86") and "@8" or ""), {force = true})
    end
end

