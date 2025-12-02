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
-- @file        build_binary.lua
--

-- imports
import("build_object")
import("private.action.build.target", {alias = "target_buildutils"})

function main(jobgraph, target, opt)
    opt = opt or {}
    local objects_group = target:fullname() .. "/objects"
    local jobsize = jobgraph:size()
    jobgraph:group(objects_group, function ()
        build_object(jobgraph, target, opt)
    end)
    local has_object_jobs = jobgraph:size() > jobsize

    -- skip link jobs if linkjobs is disabled
    if opt.linkjobs ~= false then
        -- @note We always need the link task, even if the current target does not have any object files
        -- https://github.com/xmake-io/xmake-repo/pull/7479#issuecomment-3007049158
        local link_group = target:fullname() .. "/link"
        jobgraph:group(link_group, function ()
            target_buildutils.add_linkjobs(jobgraph, target, opt)
        end)
        if has_object_jobs then
            jobgraph:add_orders(objects_group, link_group)
        end
    end
end
