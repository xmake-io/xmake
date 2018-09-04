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
-- @file        xmake.lua
--

-- remove exists md or mt
function _mfc_remove_mt_md_flags(target, flagsname)
    local flags = target:get(flagsname)
    if type(flags) == "table" then
        for key, flag in pairs(flags) do
            flag = flag:lower()
            if flag:find("[/%-]mt") or flag:find("[/%-]md") then
                flags[key] = nil
            end
        end
    elseif type(flags) == "string" then
        local flag = flags:lower()
        if flag:find("[/%-]mt") or flag:find("[/%-]md") then
            flags = {}
        end
    end
    target:set(flagsname, flags)
end

-- remove exists settings
function _mfc_remove_flags(target)
    local ldflags = target:get("ldflags")
    for key, ldflag in pairs(ldflags) do
        ldflag = ldflag:lower()
        if ldflag:find("[/%-]subsystem:") then
            ldflags[key] = nil
            break
        end
    end
    target:set("ldflags", ldflags)
    
    -- remove defines /DMT /DMTd /DMD /DMDd
    local defines = target:get("defines")
    for key, define in pairs(defines) do
        define = define:lower()
        if define:find("[/%-]dmt") or define:find("[/%-]dmd") then
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

-- check unicode
function _mfc_check_is_unicode(target)
    local defines = target:get("defines")
    for key, define in pairs(defines) do
        define = define:lower()
        if define:find("unicode") or define:find("_unicode") then
            return true
        end
    end
    return false
end

-- apply shared mfc settings
function _mfc_shared(target)

    -- remove some exists flags
    _mfc_remove_flags(target)

    -- add flags
    target:add("ldflags", "-subsystem:windows", {force = true})

    -- set runtimelibrary
    target:add("cxflags", ifelse(is_mode("debug"), "-MDd", "-MD"))
    target:add("defines", "AFX", "_AFXDLL")
end

-- apply static mfc settings
function _mfc_static(target)

    -- remove some exists flags
    _mfc_remove_flags(target)

    -- add flags
    target:add("ldflags", "-subsystem:windows", {force = true})
    target:add("ldflags", "-force", {force = true})

    -- set runtimelibrary
    target:add("cxflags", ifelse(is_mode("debug"), "-MTd", "-MT"))
end

-- apply appliction settings use static mfc
function mfc_static_app(target)

    -- static common
    _mfc_static(target)

    -- set kind: binary
    target:set("kind", "binary")

    -- set entry
    target:add("ldflags", ifelse(_mfc_check_is_unicode(target), "-entry:wWinMainCRTStartup", "-entry:WinMainCRTStartup"), {force = true})
end

-- apply appliction settings use shared mfc
function mfc_shared_app(target)

    -- static common
    _mfc_shared(target)

    -- set kind: binary
    target:set("kind", "binary")

    -- set entry
    target:add("ldflags", ifelse(_mfc_check_is_unicode(target), "-entry:wWinMainCRTStartup", "-entry:WinMainCRTStartup"), {force = true})
end