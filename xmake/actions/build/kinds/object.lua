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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        object.lua
--

-- imports
import("core.base.option")
import("core.project.rule")
import("core.project.config")
import("core.project.project")
import("private.async.runjobs")

-- build source files with the custom rule
function _build_files_with_rule(target, sourcebatch, opt, suffix)

    -- the rule name
    local rulename = assert(sourcebatch.rulename, "unknown rule for sourcebatch!")

    -- get rule instance
    local ruleinst = assert(project.rule(rulename) or rule.rule(rulename), "unknown rule: %s", rulename)

    -- on_build_files?
    local on_build_files = ruleinst:script("build_files" .. (suffix and ("_" .. suffix) or ""))
    if on_build_files then
        on_build_files(target, sourcebatch, opt)
    else
        -- get the build file script
        local on_build_file = ruleinst:script("build_file" .. (suffix and ("_" .. suffix) or ""))
        if on_build_file then

            -- get the max job count
            local jobs = tonumber(option.get("jobs") or "4")

            -- run build jobs for each source file 
            local curdir = os.curdir()
            local sourcecount = #sourcebatch.sourcefiles
            runjobs("build_files", function (index)

                -- get source file
                local sourcefile = sourcebatch.sourcefiles[index]

                -- do build file
                on_build_file(target, sourcefile, {sourcekind = sourcebatch.sourcekind, progress = opt.progress})

            end, {total = sourcecount, comax = jobs})
        end
    end
end

-- do build files
function _do_build_files(target, sourcebatch, opt)
    _build_files_with_rule(target, sourcebatch, opt)
end

-- build files
function _build_files(target, sourcebatch, opt)

    -- do before build
    local before_build_files = target:script("build_files_before")
    if before_build_files then
        before_build_files(target, sourcebatch, opt)
    end

    -- do build
    local on_build_files = target:script("build_files")
    if on_build_files then
        opt.origin = _do_build_files
        on_build_files(target, sourcebatch, opt)
        opt.origin = nil
    else
        _do_build_files(target, sourcebatch, opt)
    end

    -- do after build
    local after_build_files = target:script("build_files_after")
    if after_build_files then
        after_build_files(target, sourcebatch, opt)
    end
end

-- build source files
function build_sourcefiles(target, sourcebatches, opt)

    -- init options
    opt = opt or {}

    -- build source batches with custom rules before building other sources
    for _, sourcebatch in pairs(sourcebatches) do
        _build_files_with_rule(target, sourcebatch, opt, "before")
    end

    -- build source batches
    local sourcetotal = target:sourcecount()
    for _, sourcebatch in pairs(sourcebatches) do
        _build_files(target, sourcebatch, opt)
    end

    -- build source batches with custom rules after building other sources
    for _, sourcebatch in pairs(sourcebatches) do
        _build_files_with_rule(target, sourcebatch, opt, "after")
    end
end

-- build objects for the given target
function build(target, opt)

    -- build source files
    build_sourcefiles(target, target:sourcebatches(), opt)
end

