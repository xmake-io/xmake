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
-- @file        link_objects.lua
--

-- imports
import("core.base.option")
import("core.tool.linker")
import("core.tool.compiler")
import("core.project.depend")
import("utils.progress")
import("build_object")
import("private.action.build.target", {alias = "target_buildutils"})

-- do link target
function _do_link_target(target, opt)
    local linkinst = linker.load(target:kind(), target:sourcekinds(), {target = target})
    local linkflags = linkinst:linkflags({target = target})

    -- need build this target?
    local depfiles = target_buildutils.get_linkdepfiles(target)
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

function main(jobgraph, target, opt)
    opt = opt or {}
    local buildcmds = opt.buildcmds
    local linkjob = target:fullname() .. "/link_objects"
    jobgraph:add(linkjob, function (index, total, opt)
        if not buildcmds then
            _do_link_target(target, opt)
        end
    end)
end
