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
-- @file        build_files.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.config")
import("core.project.project")
import("private.async.jobpool")
import("private.async.runjobs")
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

-- add batch jobs
function _add_batchjobs(batchjobs, rootjob, target, filepatterns)

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
        return object.add_batchjobs_for_sourcefiles(batchjobs, rootjob, target, newbatches)
    else
        return rootjob, rootjob
    end
end

-- add batch jobs for the given target
function _add_batchjobs_for_target(batchjobs, rootjob, target, filepatterns)

    -- has been disabled?
    if target:get("enabled") == false then
        return
    end

    -- add batch jobs for target
    return _add_batchjobs(batchjobs, rootjob, target, filepatterns)
end

-- add batch jobs for the given target and deps
function _add_batchjobs_for_target_and_deps(batchjobs, rootjob, jobrefs, target, filepatterns)
    local targetjob_ref = jobrefs[target:name()]
    if targetjob_ref then
        batchjobs:add(targetjob_ref, rootjob)
    else
        local targetjob, targetjob_root = _add_batchjobs_for_target(batchjobs, rootjob, target, filepatterns)
        if targetjob and targetjob_root then
            jobrefs[target:name()] = targetjob_root
            for _, depname in ipairs(target:get("deps")) do
                _add_batchjobs_for_target_and_deps(batchjobs, targetjob, jobrefs, project.target(depname), filepatterns)
            end
        end
    end
end

-- get batch jobs
function _get_batchjobs(targetname, filepatterns)

    -- get root targets
    local targets_root = {}
    if targetname then
        table.insert(targets_root, project.target(targetname))
    else
        local depset = hashset.new()
        local targets = {}
        for _, target in pairs(project.targets()) do
            local default = target:get("default")
            if default == nil or default == true or option.get("all") then
                for _, depname in ipairs(target:get("deps")) do
                    depset:insert(depname)
                end
                table.insert(targets, target)
            end
        end
        for _, target in pairs(targets) do
            if not depset:has(target:name()) then
                table.insert(targets_root, target)
            end
        end
    end

    -- generate batch jobs for default or all targets
    local jobrefs = {}
    local batchjobs = jobpool.new()
    for _, target in pairs(targets_root) do
        _add_batchjobs_for_target_and_deps(batchjobs, batchjobs:rootjob(), jobrefs, target, filepatterns)
    end
    return batchjobs
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

    -- build all jobs
    local batchjobs = _get_batchjobs(targetname, filepatterns)
    if batchjobs and batchjobs:size() > 0 then
        local curdir = os.curdir()
        runjobs("build_files", batchjobs, {comax = option.get("jobs") or 1, curdir = curdir})
        os.cd(curdir)
    end
end


