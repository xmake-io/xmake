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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        object.lua
--

-- imports
import("core.base.option")
import("core.project.rule")
import("core.project.config")
import("core.project.project")

-- build source files with the custom rule
function _build_files_for_rule(target, sourcebatch, jobs, suffix)

    -- the rule name
    local rulename = sourcebatch.rulename
    local buildinfo = _g.buildinfo

    -- get rule instance
    local ruleinst = project.rule(rulename) or rule.rule(rulename)
    assert(ruleinst, "unknown rule: %s", rulename)

    -- on_build_files?
    local on_build_files = ruleinst:script("build_files" .. (suffix and ("_" .. suffix) or ""))
    if on_build_files then

        -- calculate progress
        local progress = (buildinfo.targetindex + buildinfo.sourceindex / buildinfo.sourcecount) * 100 / buildinfo.targetcount

        -- do build files
        on_build_files(target, sourcebatch, {jobs = jobs, progress = progress})
    else
        -- get the build file script
        local on_build_file = ruleinst:script("build_file" .. (suffix and ("_" .. suffix) or ""))
        if on_build_file then

            -- run build jobs for each source file 
            local curdir = os.curdir()
            process.runjobs(function (index)

                -- force to set the current directory first because the other jobs maybe changed it
                os.cd(curdir)

                -- calculate progress
                local progress = ((buildinfo.targetindex + (buildinfo.sourceindex + index - 1) / buildinfo.sourcecount) * 100 / buildinfo.targetcount)
                if suffix then
                    progress = ((buildinfo.targetindex + (suffix == "before" and buildinfo.sourceindex or buildinfo.sourcecount) / buildinfo.sourcecount) * 100 / buildinfo.targetcount)
                end

                -- get source file
                local sourcefile = sourcebatch.sourcefiles[index]

                -- do build file
                on_build_file(target, sourcefile, {sourcekind = sourcebatch.sourcekind, progress = progress})

            end, #sourcebatch.sourcefiles, jobs)
        end
    end
end

-- do build files
function _do_build_files(target, sourcebatch, opt)

    -- compile source files with custom rule
    if sourcebatch.rulename then
        _build_files_for_rule(target, sourcebatch, opt.jobs)
    end
end

-- build files
function _build_files(target, sourcebatch, jobs)

    -- calculate progress
    local buildinfo = _g.buildinfo
    local progress = (buildinfo.targetindex + buildinfo.sourceindex / buildinfo.sourcecount) * 100 / buildinfo.targetcount

    -- init build option
    local opt = {jobs = jobs, progress = progress}

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

    -- update object index
    buildinfo.sourceindex = buildinfo.sourceindex + #sourcebatch.sourcefiles

    -- do after build
    local after_build_files = target:script("build_files_after")
    if after_build_files then
        after_build_files(target, sourcebatch, opt)
    end
end

-- build source files
function build_sourcefiles(target, buildinfo, sourcebatches)

    -- get the max job count
    local jobs = tonumber(option.get("jobs") or "4")

    -- save buildinfo
    _g.buildinfo = buildinfo

    -- build source batches with custom rules before building other sources
    for _, sourcebatch in pairs(sourcebatches) do
        if sourcebatch.rulename then
            _build_files_for_rule(target, sourcebatch, jobs, "before")
        end
    end

    -- build source batches
    for _, sourcebatch in pairs(sourcebatches) do
        _build_files(target, sourcebatch, jobs)
    end

    -- build source batches with custom rules after building other sources
    for _, sourcebatch in pairs(sourcebatches) do
        if sourcebatch.rulename then
            _build_files_for_rule(target, sourcebatch, jobs, "after")
        end
    end
end

-- build objects for the given target
function build(target, buildinfo)

    -- init source index and count
    buildinfo.sourceindex = 0
    buildinfo.sourcecount = target:sourcecount()

    -- build source files
    build_sourcefiles(target, buildinfo, target:sourcebatches())
end

