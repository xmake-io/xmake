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
-- @file        jobgraph.lua
--

-- imports
import("core.base.object")
import("core.base.list")
import("core.base.graph")

-- define module
local jobgraph = jobgraph or object {_init = {"_jobs", "_graph"}}

-- get jobs
function jobgraph:jobs()
    return self._jobs
end

-- tostring
function jobgraph:__tostring()
    return string.format("<jobgraph:%s>", self:jobs():size())
end

-- new a jobgraph
function new()
    return jobgraph {list.new(), graph.new(true)}
end
