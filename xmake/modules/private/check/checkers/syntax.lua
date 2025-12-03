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
import("core.cache.memcache")
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
    {"j", "jobs",       "kv", tostring(os.default_njob()),
                                    "Set the number of parallel check jobs."},
    {"v", "verbose",    "k",  nil,   "Print lots of verbose information for users."},
    {"D", "diagnosis",  "k",  nil,   "Print lots of diagnosis information (backtrace, check info ..) only for developers."},
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

-- validate targets and enable syntax-only
function _validate_and_enable_targets(opt)
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

    -- check if any target has C++ rules and enable syntax-only
    local cpp_targets = {}
    for _, target in ipairs(targets) do
        if _has_cpp_rules(target) then
            -- check if compiler supports syntax-only check
            if not _check_compiler_support(target) then
                wprint("target(%s): current compiler does not support syntax-only check", target:name())
            else
                table.insert(cpp_targets, target)
            end
        else
            wprint("target(%s): syntax check currently only supports C/C++ targets", target:name())
        end
    end

    -- enable syntax-only via memcache
    if #cpp_targets > 0 then
        memcache.set("syntax_check", "enabled", true)
    end

    -- if no C++ target found, return false to skip checking
    if #cpp_targets == 0 then
        return false
    end
    return true
end

-- do check
function _check(opt)
    opt = opt or {}

    local sourcefiles = opt.files
    local targetnames = opt.targets
    local jobs = opt.jobs and tonumber(opt.jobs) or nil
    
    local check_time = os.mclock()
    local build_opt = {linkjobs = false}
    if jobs then
        build_opt.jobs = jobs
    end
    if sourcefiles then
        build_opt.sourcefiles = sourcefiles
        build_files(targetnames, build_opt)
    else
        build(targetnames, build_opt)
    end
    check_time = os.mclock() - check_time
    progress.show(100, "${color.success}syntax check ok, spent %.3fs", check_time / 1000)
end

function main(argv)
    -- parse arguments
    local args = option.parse(argv or {}, options, "Check the project sourcecode syntax without linking."
                                           , ""
                                           , "Usage: xmake check syntax [options]")

    -- save option context
    option.save()

    -- set verbose and diagnosis if specified
    if args.verbose then
        option.set("verbose", true)
    end
    if args.diagnosis then
        option.set("diagnosis", true)
    end

    -- lock the whole project
    project.lock()

    -- disable ccache after config
    project.policy_set("build.ccache", false)

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- it will call on_config
    project.load_targets()

    -- validate targets and enable syntax-only
    if _validate_and_enable_targets(args) then
        _check(args)
    end

    -- leave project directory
    os.cd(oldir)

    -- unlock the whole project
    project.unlock()

    -- restore option context
    option.restore()
end

