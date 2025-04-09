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
-- @file        build.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("private.service.distcc_build.client", {alias = "distcc_build_client"})
import("private.action.build.target", {alias = "target_buildutils"})
import("deprecated.build", {alias = "deprecated_build"})

-- run prepare jobs
function _prepare(targets_root, opt)
    opt = opt or {}
    opt.job_kind = "prepare"
    opt.progress_factor = 0.05
    target_buildutils.run_targetjobs(targets_root, opt)
end

-- run build jobs
function _build(targets_root, opt)
    opt = opt or {}
    opt.job_kind = "build"
    opt.progress_factor = 0.95
    if distcc_build_client.is_connected() then
        opt.distcc = distcc_build_client.singleton()
    end
    target_buildutils.run_targetjobs(targets_root, opt)
end

function main(targetnames, opt)

    -- get root targets
    local targets_root = target_buildutils.get_root_targets(targetnames, opt)

    -- prepare to build
    _prepare(targets_root, opt)

    -- do build
    if project.policy("build.jobgraph") then
        _build(targets_root, opt)
    else
        deprecated_build(targets_root, opt)
    end
end
