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
function _rule_remove_mt_md_flags(target, flagsname)
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
function _rule_remove_exists_flags(target)
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
    _rule_remove_mt_md_flags(target, "cflags")
    
    -- remove c,cpp /MD,/MT
    _rule_remove_mt_md_flags(target, "cxflags")
    
    -- remove cpp /MD,/MT
    _rule_remove_mt_md_flags(target, "cxxflags")
end

-- check unicode
function _rule_check_is_unicode(target)
    local defines = target:get("defines")
    for key, define in pairs(defines) do
        define = define:lower()
        if define:find("unicode") or define:find("_unicode") then
            return true
        end
    end
    return false
end

-- define rule: application
rule("win.sdk.application")

    -- add deps
    add_deps("win.sdk.dotnet")

    -- after load
    after_load(function (target)

        -- set kind: binary
        target:set("kind", "binary")

        -- set subsystem: windows
        local subsystem = false
        for _, ldflag in ipairs(target:get("ldflags")) do
            ldflag = ldflag:lower()
            if ldflag:find("[/%-]subsystem:") then
                subsystem = true
                break
            end
        end
        if not subsystem then
            target:add("ldflags", "-subsystem:windows", {force = true})
        end

        -- add links
        target:add("links", "kernel32", "user32", "gdi32", "winspool", "comdlg32", "advapi32")
        target:add("links", "shell32", "ole32", "oleaut32", "uuid", "odbc32", "odbccp32", "comctl32")
        target:add("links", "cfgmgr32", "comdlg32", "setupapi", "strsafe", "shlwapi")
    end)

-- define rule: sharedmfcapp
rule("win.sdk.mfcapp.shared")

    -- save local functions
    local remove_exists_flags = _rule_remove_exists_flags
    local check_is_unicode = _rule_check_is_unicode

    -- after load
    after_load(function (target)

        -- set kind: binary
        target:set("kind", "binary")

        -- remove some exists flags
        remove_exists_flags(target)

        -- add flags
        target:add("ldflags", "-subsystem:windows", {force = true})
        target:add("ldflags", ifelse(check_is_unicode(target), "-entry:wWinMainCRTStartup", "-entry:WinMainCRTStartup"), {force = true})

        -- set runtimelibrary
        target:add("cxflags", ifelse(is_mode("debug"), "-MDd", "-MD"))
        target:add("defines", "AFX", "_AFXDLL")

        -- add mfc flags
        target:values_set("project.vs.mfc", true)
    end)


-- define rule: staticmfcapp
rule("win.sdk.mfcapp.static")

    -- save local functions
    local remove_exists_flags = _rule_remove_exists_flags
    local check_is_unicode = _rule_check_is_unicode

    -- after load
    after_load(function (target)

        -- set kind: binary
        target:set("kind", "binary")

        -- remove some exists flags
        remove_exists_flags(target)

        -- add flags
        target:add("ldflags", "-subsystem:windows", {force = true})
        target:add("ldflags", "-force", {force = true})
        target:add("ldflags", ifelse(check_is_unicode(target), "-entry:wWinMainCRTStartup", "-entry:WinMainCRTStartup"), {force = true})

        -- set runtimelibrary
        target:add("cxflags", ifelse(is_mode("debug"), "-MTd", "-MT"))

        -- add mfc flags
        target:values_set("project.vs.mfc", true)
    end)

