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
-- @author      xigal
-- @file        xmake.lua
--

-- remove exists md or mt
function _mfc_remove_mt_md_flags(target, flagsname)
    local flags = table.wrap(target:get(flagsname))
    for key, flag in pairs(flags) do
        flag = flag:lower():trim()
        if flag:find("^[/%-]?mt[d]?$") or flag:find("^[/%-]?md[d]?$") then
            flags[key] = nil
        end
    end
    target:set(flagsname, flags)
end

-- remove exists settings
function _mfc_remove_flags(target)
    local ldflags = table.wrap(target:get("ldflags"))
    for key, ldflag in pairs(ldflags) do
        ldflag = ldflag:lower():trim()
        if ldflag:find("[/%-]subsystem:") then
            ldflags[key] = nil
            break
        end
    end
    target:set("ldflags", ldflags)
    
    -- remove defines MT MTd MD MDd
    local defines = table.wrap(target:get("defines"))
    for key, define in pairs(defines) do
        define = define:lower():trim()
        if define:find("^[/%-]?mt[d]?$") or define:find("^[/%-]?md[d]?$") then
            defines[key] = nil
        end
    end
    target:set("defines", defines)
    
    -- remove c /MD,/MT
    _mfc_remove_mt_md_flags(target, "cflags")
    
    -- remove c,cpp /MD,/MT
    _mfc_remove_mt_md_flags(target, "cxflags")
    
    -- remove cpp /MD,/MT
    _mfc_remove_mt_md_flags(target, "cxxflags")
end

-- get application entry
function mfc_application_entry(target)
    local defines = target:get("defines")
    for key, define in pairs(defines) do
        define = define:lower():trim()
        if define:find("^[_]?unicode$") then
            return "-entry:wWinMainCRTStartup"
        end
    end
    return "-entry:WinMainCRTStartup"
end

-- apply shared mfc settings
function mfc_shared(target)

    -- remove some exists flags
    _mfc_remove_flags(target)

    -- add flags
    target:add("ldflags", "-subsystem:windows", {force = true})

    -- set runtimelibrary
    target:add("cxflags", ifelse(is_mode("debug"), "-MDd", "-MD"))
    target:add("defines", "AFX", "_AFXDLL")
end

-- apply static mfc settings
function mfc_static(target)

    -- remove some exists flags
    _mfc_remove_flags(target)

    -- add flags
    target:add("ldflags", "-subsystem:windows", {force = true})
    target:add("ldflags", "-force", {force = true})

    -- set runtimelibrary
    target:add("cxflags", ifelse(is_mode("debug"), "-MTd", "-MT"))
end