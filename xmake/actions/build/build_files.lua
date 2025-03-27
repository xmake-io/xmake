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
-- @file        build_files.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.config")
import("core.project.project")
import("target_utils")
import("deprecated.build_files", {alias = "deprecated_build_files"})

function _prepare_files(targets_root, opt)
end

function _build_files(targets_root, opt)
end

function main(targetnames, opt)

    -- get root targets
    local targets_root = target_utils.get_root_targets(targetnames, opt)

    -- prepare to build files
    _prepare_files(targets_root, opt)

    -- do build files
    if project.policy("build.jobgraph") then
        _build_files(targets_root, opt)
    else
        deprecated_build_files(targets_root, opt)
    end
end


