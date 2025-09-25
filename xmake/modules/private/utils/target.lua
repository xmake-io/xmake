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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        target.lua
--

-- imports
import("core.base.option")
import("core.project.project")

-- Is this target has these tools?
function has_tool(target, toolkind, ...)
    local _, toolname = target:tool(toolkind)
    if toolname then
        -- We need compatibility with gcc/g++, clang/clang++ for c++ compiler/linker
        -- @see https://github.com/xmake-io/xmake/issues/6852
        local trim_xx = false
        if toolname == "clangxx" or toolname == "gxx" then
            toolname = toolname:rtrim("xx")
            trim_xx = true
        end
        for _, v in ipairs(table.pack(...)) do
            if trim_xx then
                v = v:rtrim("xx")
            end
            if v and toolname:find("^" .. v:gsub("%-", "%%-") .. "$") then
                return true
            end
        end
    end
end

-- does this flag belong to this tool?
-- @see https://github.com/xmake-io/xmake/issues/3022
--
-- e.g.
-- for all: add_cxxflags("-g")
-- only for clang: add_cxxflags("clang::-stdlib=libc++")
-- only for clang and multiple flags: add_cxxflags("-stdlib=libc++", "-DFOO", {tools = "clang"})
--
function flag_belong_to_tool(flag, toolinst, extraconf)
    local for_this_tool = true
    local flagconf = extraconf and extraconf[flag]
    if type(flag) == "string" and flag:find("::", 1, true) then
        for_this_tool = false
        local splitinfo = flag:split("::", {plain = true})
        local toolname = splitinfo[1]
        local realname = toolinst:name()
        -- We need compatibility with gcc/g++, clang/clang++ for c++ compiler/linker
        -- @see https://github.com/xmake-io/xmake/issues/6852
        if realname == "clangxx" or realname == "gxx" then
            toolname = toolname:rtrim("xx")
            realname = realname:rtrim("xx")
        end
        if toolname == realname then
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
        flag = flag_belong_to_tool(flag, toolinst, extraconf)
        if flag then
            table.insert(result, flag)
        end
    end
    return result
end

-- get project targets
function get_project_targets()
    local selected_target = option.get("target")
    if selected_target then
        -- return table.wrap(project.target(selected_target))
        return { project.target(selected_target) }
    end
    return project.targets()
end
