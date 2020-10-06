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
-- @file        static.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.tool.linker")
import("core.tool.compiler")
import("core.project.depend")
import("private.utils.progress")
import("object", {alias = "add_batchjobs_for_object"})

-- do link target
function _do_link_target(target, opt)

    -- load linker instance
    local linkinst = linker.load(target:targetkind(), target:sourcekinds(), {target = target})

    -- get link flags
    local linkflags = linkinst:linkflags({target = target})

    -- get object files
    local objectfiles = target:objectfiles()

    -- need build this target?
    local depfiles = objectfiles
    for _, dep in ipairs(target:orderdeps()) do
        if dep:targetkind() == "static" then
            if depfiles == objectfiles then
                depfiles = table.copy(objectfiles)
            end
            table.insert(depfiles, dep:targetfile())
        end
    end
    local depvalues = {linkinst:program(), linkflags}
    depend.on_changed(function ()

        -- TODO make headers (deprecated)
        local srcheaders, dstheaders = target:headers()
        if srcheaders and dstheaders then
            local i = 1
            for _, srcheader in ipairs(srcheaders) do
                local dstheader = dstheaders[i]
                if dstheader then
                    os.cp(srcheader, dstheader)
                end
                i = i + 1
            end
        end


        -- the target file
        local targetfile = target:targetfile()

        -- is verbose?
        local verbose = option.get("verbose")

        -- trace progress info
        progress.show(opt.progress, "${color.build.target}archiving.$(mode) %s", path.filename(targetfile))

        -- trace verbose info
        if verbose then
            -- show the full link command with raw arguments, it will expand @xxx.args for msvc/link on windows
            print(linkinst:linkcmd(objectfiles, targetfile, {linkflags = linkflags, rawargs = true}))
        end

        -- link it
        if not option.get("dry-run") then
            assert(linkinst:link(objectfiles, targetfile, {linkflags = linkflags}))
        end

    end, {dependfile = target:dependfile(), lastmtime = os.mtime(target:targetfile()), values = depvalues, files = depfiles})
end

-- on link the given target
function _on_link_target(target, opt)

    -- link target with rules
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_link = r:script("link")
        if on_link then
            on_link(target, opt)
            done = true
        end
    end
    if done then return end

    -- do link
    _do_link_target(target, opt)
end

-- link target
function _link_target(target, opt)

    -- do before link for target
    local before_link = target:script("link_before")
    if before_link then
        before_link(target, opt)
    end

    -- do before link for rules
    for _, r in ipairs(target:orderules()) do
        local before_link = r:script("link_before")
        if before_link then
            before_link(target, opt)
        end
    end

    -- on link
    target:script("link", _on_link_target)(target, opt)

    -- do after link for target
    local after_link = target:script("link_after")
    if after_link then
        after_link(target, opt)
    end

    -- do after link for rules
    for _, r in ipairs(target:orderules()) do
        local after_link = r:script("link_after")
        if after_link then
            after_link(target, opt)
        end
    end
end

-- add batch jobs for building static target
function main(batchjobs, rootjob, target)

    -- add link job
    local job_link = batchjobs:addjob(target:name() .. "/link", function (index, total)
        _link_target(target, {progress = (index * 100) / total})
    end, rootjob)

    -- we need only return and depend the link job for each target,
    -- so we can compile the source files for each target in parallel
    --
    -- unless call set_policy("build.across_targets_in_parallel", false) to disable to build across targets in parallel.
    --
    local job_objects = add_batchjobs_for_object(batchjobs, job_link, target)
    return target:policy("build.across_targets_in_parallel") == false and job_objects or job_link, job_objects
end
