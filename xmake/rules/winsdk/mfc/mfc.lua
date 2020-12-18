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
-- @author      xigal, ruki
-- @file        xmake.lua
--

-- remove exists md or mt
function _remove_mt_md_flags(target, flagsname)
    local flags = table.wrap(target:get(flagsname))
    for i = #flags, 1, -1 do
        flag = flags[i]:lower():trim()
        if flag:find("^[/%-]?mt[d]?$") or flag:find("^[/%-]?md[d]?$") then
            table.remove(flags, i)
        end
    end
    target:set(flagsname, flags)
end

-- remove exists settings
function _remove_flags(target)
    local ldflags = table.wrap(target:get("ldflags"))
    for i = #ldflags, 1, -1 do
        ldflag = ldflags[i]:lower():trim()
        if ldflag:find("[/%-]subsystem:") then
            table.remove(ldflags, i)
            break
        end
    end
    target:set("ldflags", ldflags)

    -- remove defines MT MTd MD MDd
    local defines = table.wrap(target:get("defines"))
    for i = #defines, 1, -1 do
        define = defines[i]:lower():trim()
        if define:find("^[/%-]?mt[d]?$") or define:find("^[/%-]?md[d]?$") then
            table.remove(defines, i)
        end
    end
    target:set("defines", defines)

    -- remove c /MD,/MT
    _remove_mt_md_flags(target, "cflags")

    -- remove c,cpp /MD,/MT
    _remove_mt_md_flags(target, "cxflags")

    -- remove cpp /MD,/MT
    _remove_mt_md_flags(target, "cxxflags")
end

-- apply mfc library settings
function library(target, kind)

    -- set kind: static/shared
    target:set("kind", kind)

    -- set runtime library
    if kind == "static" then
        target:add("cxflags", is_mode("debug") and "-MTd" or "-MT")
    else
        target:add("cxflags", is_mode("debug") and "-MDd" or "-MD")
        target:add("defines", "AFX", "_AFXDLL")
    end
end

-- apply mfc application settings
function application(target, mfc_kind)

    -- set kind: binary
    target:set("kind", "binary")

    -- remove some exists flags
    _remove_flags(target)

    -- set windows subsystem
    target:add("ldflags", "-subsystem:windows", {force = true})

    -- forces a link to complete even with unresolved symbols
    if mfc_kind == "static" then
        target:add("ldflags", "-force", {force = true})
    end

    -- set runtime library
    if mfc_kind == "static" then
        target:add("cxflags", is_mode("debug") and "-MTd" or "-MT")
    else
        target:add("cxflags", is_mode("debug") and "-MDd" or "-MD")
        target:add("defines", "AFX", "_AFXDLL")
    end

    -- set startup entry
    local unicode = false
    for _, define in ipairs(target:get("defines")) do
        define = define:lower():trim()
        if define:find("^[_]?unicode$") then
            unicode = true
            break
        end
    end
    target:add("ldflags", unicode and "-entry:wWinMainCRTStartup" or "-entry:WinMainCRTStartup", {force = true})
end
