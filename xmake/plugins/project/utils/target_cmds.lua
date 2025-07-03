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
-- @file        target_cmds.lua
--

-- imports
import("core.project.project")
import("core.project.config")
import("core.base.hashset")
import("core.project.rule")
import("private.utils.batchcmds")
import("private.action.build.target", {alias = "target_buildutils"})

-- prepare targets
function prepare_targets()
    local targets_root = target_buildutils.get_root_targets()
    target_buildutils.run_targetjobs(targets_root, {job_kind = "prepare"})
end

-- get target buildcmds
function get_target_buildcmds(target, opt)
    opt = opt or {}
    local progress_wrapper = {}
    progress_wrapper.current = function ()
        return count
    end
    progress_wrapper.total = function ()
        return total
    end
    progress_wrapper.percent = function ()
        if total and total > 0 then
            return math.floor((count * 100) / total)
        else
            return 0
        end
    end
    debug.setmetatable(progress_wrapper, {
        __tostring = function ()
            -- we do not output any progress info for the project generators
            return ""
        end
    })
    local buildcmds = batchcmds.new({target = target})
    local jobgraph = target_buildutils.get_targetjobs({target}, {
        job_kind = "build",
        buildcmds = buildcmds,
        with_stages = hashset.from(opt.stages or {}),
        ignored_rules = hashset.from(opt.ignored_rules or {})})
    if jobgraph and not jobgraph:empty() then
        local total = jobgraph:size()
        local index = 0
        local jobqueue = jobgraph:build()
        while true do
            local job = jobqueue:getfree()
            if job then
                if job.run then
                    job.run(index, total, {progress = progress_wrapper})
                end
                jobqueue:remove(job)
                index = index + 1
            else
                break
            end
        end
    end
    return buildcmds:cmds()
end

