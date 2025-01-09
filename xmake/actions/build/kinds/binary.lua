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
-- @file        binary.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.tool.linker")
import("core.tool.compiler")
import("core.project.depend")
import("utils.progress")
import("private.utils.batchcmds")
import("object", {alias = "object_target"})
import("linkdepfiles", {alias = "get_linkdepfiles"})

-- do link target
function _do_link_target(target, opt)
    local linkinst = linker.load(target:kind(), target:sourcekinds(), {target = target})
    local linkflags = linkinst:linkflags({target = target})

    -- need build this target?
    local depfiles = get_linkdepfiles(target)
    local dryrun = option.get("dry-run")
    local depvalues = {linkinst:program(), linkflags}
    depend.on_changed(function ()
        local filename = target:filename()
        if target:namespace() then
            filename = target:namespace() .. "::" .. filename
        end
        progress.show(opt.progress, "${color.build.target}linking.$(mode) %s", filename)

        local targetfile = target:targetfile()
        local objectfiles = target:objectfiles()
        local verbose = option.get("verbose")
        if verbose then
            -- show the full link command with raw arguments, it will expand @xxx.args for msvc/link on windows
            print(linkinst:linkcmd(objectfiles, targetfile, {linkflags = linkflags, rawargs = true}))
        end

        if not dryrun then
            assert(linkinst:link(objectfiles, targetfile, {linkflags = linkflags}))
        end
    end, {dependfile = target:dependfile(),
          lastmtime = os.mtime(target:targetfile()),
          changed = target:is_rebuilt() or option.get("linkonly"),
          values = depvalues, files = depfiles, dryrun = dryrun})
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
        local on_linkcmd = r:script("linkcmd")
        if on_linkcmd then
            local batchcmds_ = batchcmds.new({target = target})
            on_linkcmd(target, batchcmds_, {progress = opt.progress})
            batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
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
        local before_linkcmd = r:script("linkcmd_before")
        if before_linkcmd then
            local batchcmds_ = batchcmds.new({target = target})
            before_linkcmd(target, batchcmds_, {progress = opt.progress})
            batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
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
        local after_linkcmd = r:script("linkcmd_after")
        if after_linkcmd then
            local batchcmds_ = batchcmds.new({target = target})
            after_linkcmd(target, batchcmds_, {progress = opt.progress})
            batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
        end
    end
end

-- add batch jobs for building binary target
function main(batchjobs, rootjob, target)

    -- add link job
    local job_link = batchjobs:addjob(target:name() .. "/link", function (index, total, opt)
        _link_target(target, {progress = opt.progress})
    end, {rootjob = rootjob})

    -- we only need to return and depend the link job for each target,
    -- so we can compile the source files for each target in parallel
    --
    -- unless call set_policy("build.across_targets_in_parallel", false) to disable to build across targets in parallel.
    --
    local job_objects = object_target.add_batchjobs_for_object(batchjobs, job_link, target)
    return target:policy("build.across_targets_in_parallel") == false and job_objects or job_link, job_objects
end
