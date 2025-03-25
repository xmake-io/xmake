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
-- @file        prepare.lua
--

-- imports
import("core.base.option")
import("core.project.project")
import("async.runjobs")
import("async.jobgraph", {alias = "async_jobgraph"})

-- add prepare jobs for the given target
function _add_prepare_jobs_for_target(jobgraph, target)
    print("prepare", target:fullname())
end

-- add prepare jobs for the given target and deps
function _add_preprare_jobs_for_target_and_deps(jobgraph, target, targetrefs)
    local targetname = target:fullname()
    if not targetrefs[targetname] then
        targetrefs[targetname] = target
        _add_prepare_jobs_for_target(jobgraph, target)
        for _, depname in ipairs(target:get("deps")) do
            local dep = project.target(depname, {namespace = target:namespace()})
            _add_preprare_jobs_for_target_and_deps(jobgraph, dep, targetrefs)
        end
    end
end

-- get prepare jobs
function _get_prepare_jobs(targets_root, opt)
    local jobgraph = async_jobgraph.new()
    local targetrefs = {}
    for _, target in ipairs(targets_root) do
        _add_preprare_jobs_for_target_and_deps(jobgraph, target, targetrefs)
    end
    return jobgraph
end

function main(targets_root, opt)
    local jobgraph = _get_prepare_jobs(targets_root, opt)
    if jobgraph and not jobgraph:empty() then
        local curdir = os.curdir()
        runjobs("prepare", jobgraph, {on_exit = function (errors)
            import("utils.progress")
            if errors and progress.showing_without_scroll() then
                print("")
            end
        end, comax = option.get("jobs") or 1, curdir = curdir})
        os.cd(curdir)
    end
end
