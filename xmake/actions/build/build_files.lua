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
-- @file        build_files.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.environment")
import("kinds.object")

-- match source files
function _match_sourcefiles(sourcefile, filepatterns)
    for _, filepattern in ipairs(filepatterns) do
        if sourcefile:match(filepattern.pattern) == sourcefile then
            if filepattern.excludes then
                if filepattern.rootdir and sourcefile:startswith(filepattern.rootdir) then
                    sourcefile = sourcefile:sub(#filepattern.rootdir + 2)
                end
                for _, exclude in ipairs(filepattern.excludes) do
                    if sourcefile:match(exclude) == sourcefile then
                        return false
                    end
                end
            end
            return true
        end
    end
end

-- prepare jobs for target
function _prepare_jobs_for_target(jobs, target, filepatterns)

    local newbatches = {}
    local sourcecount = 0
    for rulename, sourcebatch in pairs(target:sourcebatches()) do
        local objectfiles = sourcebatch.objectfiles
        local dependfiles = sourcebatch.dependfiles
        local sourcekind  = sourcebatch.sourcekind
        for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
            if _match_sourcefiles(sourcefile, filepatterns) then
                local newbatch = newbatches[rulename] 
                if not newbatch then
                    newbatch             = {}
                    newbatch.sourcekind  = sourcekind
                    newbatch.rulename    = rulename
                    newbatch.sourcefiles = {}
                end
                table.insert(newbatch.sourcefiles, sourcefile)
                if objectfiles then
                    newbatch.objectfiles = newbatch.objectfiles or {}
                    table.insert(newbatch.objectfiles, objectfiles[idx])
                end
                if dependfiles then
                    newbatch.dependfiles = newbatch.dependfiles or {}
                    table.insert(newbatch.dependfiles, dependfiles[idx])
                end
                newbatches[rulename] = newbatch
                sourcecount = sourcecount + 1
            end
        end
    end
    if sourcecount > 0 then
        table.insert(jobs, {target = target, sourcecount = sourcecount, sourcebatches = newbatches})
    end
end

-- prepare jobs for the given target and deps
function _prepare_jobs_for_targetdeps(jobs, target, filepatterns)

    -- this target have been finished?
    if _g.finished[target:name()] then
        return 
    end

    -- make for all dependent targets
    for _, depname in ipairs(target:get("deps")) do
        _prepare_jobs_for_targetdeps(jobs, project.target(depname), filepatterns) 
    end

    -- prepare jobs for target
    _prepare_jobs_for_target(jobs, target, filepatterns)

    -- finished
    _g.finished[target:name()] = true
end

-- prepare jobs
function _prepare_jobs(targetname, filepatterns)

    -- clear finished states
    _g.finished = {}

    -- prepare jobs for the given target?
    local jobs = {}
    if targetname then
        _prepare_jobs_for_targetdeps(jobs, project.target(targetname), filepatterns)
    else
        -- prepare jobs for default or all targets
        for _, target in pairs(project.targets()) do
            local default = target:get("default")
            if default == nil or default == true or option.get("all") then
                _prepare_jobs_for_targetdeps(jobs, target, filepatterns)
            end
        end
    end

    -- get source total count
    local sourcetotal = 0
    for _, job in ipairs(jobs) do
        sourcetotal = sourcetotal + job.sourcecount
    end
    return jobs, sourcetotal
end

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
                exclude = exclude:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
                exclude = exclude:gsub("%*%*", "\001")
                exclude = exclude:gsub("%*", "\002")
                exclude = exclude:gsub("\001", ".*")
                exclude = exclude:gsub("\002", "[^/]*")
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

-- the main entry
function main(targetname, sourcefiles)

    -- convert all sourcefiles to lua pattern
    local filepatterns = _get_file_patterns(sourcefiles)

    -- prepare jobs
    local jobs, sourcetotal = _prepare_jobs(targetname, filepatterns)
    if #jobs == 0 or sourcetotal == 0 then
        return
    end

    -- enter toolchains environment
    environment.enter("toolchains")

    -- build source files
    local sourcestart = 1
    local sourcestop  = 0
    for _, job in ipairs(jobs) do

        -- compute the sub-progress range
        sourcestop = sourcestart + job.sourcecount
        local progress_start = (sourcestart * 100) / sourcetotal
        local progress_stop  = (sourcestop * 100) / sourcetotal
        local progress = {start = progress_start, stop = progress_stop}
        sourcestart = sourcestop

        -- build files
        object.build_sourcefiles(job.target, job.sourcebatches, {progress = progress})
    end

    -- leave toolchains environment
    environment.leave("toolchains")
end


