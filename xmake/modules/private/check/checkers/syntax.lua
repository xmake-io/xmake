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

    -- do check
    _check(args)

    -- leave project directory
    os.cd(oldir)

    -- unlock the whole project
    project.unlock()
end

