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
-- @file        target.lua
--

-- imports
import("core.base.option")

-- does this flag belong to this tool?
-- @see https://github.com/xmake-io/xmake/issues/3022
--
-- e.g.
-- for all: add_cxxflags("-g")
-- only for clang: add_cxxflags("clang::-stdlib=libc++")
-- only for clang and multiple flags: add_cxxflags("-stdlib=libc++", "-DFOO", {tools = "clang"})
--
function flag_belong_to_tool(target, flag, toolinst, extraconf)
    local for_this_tool = true
    local flagconf = extraconf and extraconf[flag]
    if type(flag) == "string" and flag:find("::", 1, true) then
        for_this_tool = false
        local splitinfo = flag:split("::", {plain = true})
        local toolname = splitinfo[1]
        if toolname == toolinst:name() then
            flag = splitinfo[2]
            for_this_tool = true
        end
    elseif flagconf and flagconf.tools then
        for_this_tool = table.contains(table.wrap(flagconf.tools), toolinst:name())
    end
    if for_this_tool then
        return flag
    end
end

-- translate flags in tool
function translate_flags_in_tool(target, flagkind, flags)
    local extraconf = target:extraconf(flagkind)
    local sourcekind
    local linkerkind
    if flagkind == "cflags" then
        sourcekind = "cc"
    elseif flagkind == "cxxflags" or flagkind == "cxflags" then
        sourcekind = "cxx"
    elseif flagkind == "asflags" then
        sourcekind = "as"
    elseif flagkind == "cuflags" then
        sourcekind = "cu"
    elseif flagkind == "ldflags" or flagkind == "shflags" then
        -- pass
    else
        raise("unknown flag kind %s", flagkind)
    end
    local toolinst = sourcekind and target:compiler(sourcekind) or target:linker()

    -- does this flag belong to this tool?
    -- @see https://github.com/xmake-io/xmake/issues/3022
    --
    -- e.g.
    -- for all: add_cxxflags("-g")
    -- only for clang: add_cxxflags("clang::-stdlib=libc++")
    -- only for clang and multiple flags: add_cxxflags("-stdlib=libc++", "-DFOO", {tools = "clang"})
    --
    local result = {}
    for _, flag in ipairs(flags) do
        flag = flag_belong_to_tool(target, flag, toolinst, extraconf)
        if flag then
            table.insert(result, flag)
        end
    end
    return result
end

