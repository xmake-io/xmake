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
-- @file        build_files.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.config")
import("core.project.project")
import("private.service.distcc_build.client", {alias = "distcc_build_client"})
import("private.action.build.target", {alias = "target_buildutils"})
import("deprecated.build_files", {alias = "deprecated_build_files"})

-- convert all sourcefiles to lua pattern
function _get_file_patterns(sourcefiles)
    local patterns = {}
    for _, sourcefile in ipairs(path.splitenv(sourcefiles)) do

        -- get the excludes
        local pattern  = sourcefile:trim()
        local excludes = pattern:match("|.*$")
        if excludes then excludes = excludes:split("|", {plain = true}) end

        -- translate excludes
        if excludes then
            local _excludes = {}
            for _, exclude in ipairs(excludes) do
                exclude = path.translate(exclude)
                exclude = path.pattern(exclude)
                table.insert(_excludes, exclude)
            end
            excludes = _excludes
        end

        -- translate path and remove some repeat separators
        pattern = path.translate(pattern:gsub("|.*$", ""))

        -- remove "./" or '.\\' prefix
        if pattern:sub(1, 2):find('%.[/\\]') then
            pattern = pattern:sub(3)
        end

        -- get the root directory
        local rootdir = pattern
        local startpos = pattern:find("*", 1, true)
        if startpos then
            rootdir = rootdir:sub(1, startpos - 1)
        end
        rootdir = path.directory(rootdir)

        -- convert to lua path pattern
        pattern = path.pattern(pattern)
        table.insert(patterns, {pattern = pattern, excludes = excludes, rootdir = rootdir})
    end
    return patterns
end

-- run prepare files jobs
function _prepare_files(targets_root, opt)
    opt = opt or {}
    opt.job_kind = "prepare"
    opt.progress_factor = 0.05
    opt.filepatterns = _get_file_patterns(opt.sourcefiles)
    target_buildutils.run_filejobs(targets_root, opt)
end

-- run build files jobs
function _build_files(targets_root, opt)
    opt = opt or {}
    opt.job_kind = "build"
    opt.progress_factor = 0.95
    opt.filepatterns = _get_file_patterns(opt.sourcefiles)
    if distcc_build_client.is_connected() then
        opt.distcc = distcc_build_client.singleton()
    end
    if not target_buildutils.run_filejobs(targets_root, opt) then
        wprint("%s not found!", opt.sourcefiles)
    end
end

function main(targetnames, opt)

    -- get root targets
    local targets_root = target_buildutils.get_root_targets(targetnames, opt)

    -- prepare to build files
    _prepare_files(targets_root, opt)

    -- do build files
    if project.policy("build.jobgraph") then
        _build_files(targets_root, opt)
    else
        deprecated_build_files(targets_root, opt)
    end
end


