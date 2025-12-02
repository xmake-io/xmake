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
-- @file        syntax.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.project.config")
import("core.project.project")
import("actions.build.build_files", {rootdir = os.programdir(), alias = "build_files"})
import("actions.build.build", {rootdir = os.programdir(), alias = "build"})
import("utils.progress")

-- the syntax check options
local options = {
    {'f', "files",      "kv", nil,   "Check the given source files.",
                                    "e.g.",
                                    "    - xmake check syntax -f src/foo.cpp",
                                    "    - xmake check syntax -f 'src/*.cpp'"},
    {nil, "targets",    "vs", nil,   "Check the sourcefiles of the given target.",
                                    "e.g.",
                                    "    - xmake check syntax",
                                    "    - xmake check syntax [targets]"}
}

-- check if target has C++ rules
function _has_cpp_rules(target)
    for _, ruleinst in ipairs(target:orderules()) do
        local rulename = ruleinst:name()
        if rulename == "c++.build" or rulename == "c.build" or
           rulename == "objc++.build" or rulename == "objc.build" then
            return true
        end
    end
    return false
end

-- check if compiler supports syntax-only check
function _check_compiler_support(target)
    local has_support = false
    if target:has_tool("cc", "gcc", "clang") or target:has_tool("cxx", "gxx", "clangxx") then
        -- gcc/clang: -fsyntax-only
        has_support = true
    elseif target:has_tool("cc", "cl") or target:has_tool("cxx", "cl") then
        -- MSVC: /Zs
        has_support = true
    end
    return has_support
end

-- validate targets before checking
function _validate_targets(opt)
    opt = opt or {}
    local targets = {}
    if opt.targets then
        for _, targetname in ipairs(opt.targets) do
            local target = project.target(targetname)
            if target then
                table.insert(targets, target)
            end
        end
    else
        for _, target in pairs(project.targets()) do
            if target:is_enabled() and (target:is_default() or option.get("all")) then
                table.insert(targets, target)
            end
        end
    end

    -- check if any target has C++ rules
    local has_cpp_target = false
    for _, target in ipairs(targets) do
        if _has_cpp_rules(target) then
            has_cpp_target = true
            -- check if compiler supports syntax-only check
            if not _check_compiler_support(target) then
                wprint("target(%s): current compiler does not support syntax-only check", target:name())
            end
        else
            wprint("target(%s): syntax check currently only supports C/C++ targets", target:name())
        end
    end

    -- if no C++ target found, return false to skip checking
    if not has_cpp_target then
        return false
    end
    return true
end

-- do check
function _check(opt)
    opt = opt or {}

    local sourcefiles = opt.files
    local targetnames = opt.targets
    local check_time = os.mclock()
    if sourcefiles then
        build_files(targetnames, {sourcefiles = sourcefiles, linkjobs = false})
    else
        build(targetnames, {linkjobs = false})
    end
    check_time = os.mclock() - check_time
    progress.show(100, "${color.success}syntax check ok, spent %.3fs", check_time / 1000)
end

function main(argv)
    -- parse arguments
    local args = option.parse(argv or {}, options, "Check the project sourcecode syntax without linking."
                                           , ""
                                           , "Usage: xmake check syntax [options]")

    -- lock the whole project
    project.lock()

    -- enable syntax-only policy and disable ccache via config
    config.set("policies", "build.c++.syntax_only,build.ccache:n")
    
    -- config it first
    task.run("config", {}, {disable_dump = true})

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- validate targets before checking
    if _validate_targets(args) then
        -- do check
        _check(args)
    end

    -- leave project directory
    os.cd(oldir)

    -- unlock the whole project
    project.unlock()
end

