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
-- @file        devlink.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.project.config")
import("core.project.depend")
import("core.tool.linker")
import("core.platform.platform")
import("utils.progress")

-- @see https://devblogs.nvidia.com/separate-compilation-linking-cuda-device-code/
function main(target, opt)

    -- disable devlink?
    --
    -- @note cuda.build.devlink value will be deprecated
    --
    local devlink = target:policy("build.cuda.devlink") or target:values("cuda.build.devlink")
    if devlink == false then
        return
    end

    -- only for binary/shared by default
    -- https://github.com/xmake-io/xmake/issues/1976
    if not (devlink == true or target:is_binary() or target:is_shared()) then
        return
    end

    -- load linker instance
    local linkinst = linker.load("gpucode", "cu", {target = target})

    -- init culdflags
    local culdflags = {"-dlink"}

    -- add shared flag
    if target:is_shared() then
        table.insert(culdflags, "-shared")
    end

    -- get link flags
    local linkflags = linkinst:linkflags({target = target, configs = {force = {culdflags = culdflags}}})

    -- get target file
    local targetfile = target:objectfile(path.join("rules", "cuda", "devlink", target:basename() .. "_gpucode.cu"))

    -- get object files
    local objectfiles = nil
    for _, sourcebatch in pairs(target:sourcebatches()) do
        if sourcebatch.sourcekind == "cu" then
            objectfiles = sourcebatch.objectfiles
        end
    end
    if not objectfiles then
        return
    end

    -- insert gpucode.o to the object files
    table.insert(target:objectfiles(), targetfile)

    -- need build this target?
    local depfiles = objectfiles
    for _, dep in ipairs(target:orderdeps()) do
        if dep:kind() == "static" then
            if depfiles == objectfiles then
                depfiles = table.copy(objectfiles)
            end
            table.insert(depfiles, dep:targetfile())
        end
    end
    local dryrun = option.get("dry-run")
    local depvalues = {linkinst:program(), linkflags}
    depend.on_changed(function ()

        -- is verbose?
        local verbose = option.get("verbose")

        -- trace progress info
        progress.show(opt.progress, "${color.build.target}devlinking.$(mode) %s", path.filename(targetfile))

        -- trace verbose info
        if verbose then
            -- show the full link command with raw arguments, it will expand @xxx.args for msvc/link on windows
            print(linkinst:linkcmd(objectfiles, targetfile, {linkflags = linkflags, rawargs = true}))
        end

        -- link it
        if not dryrun then
            assert(linkinst:link(objectfiles, targetfile, {linkflags = linkflags}))
        end

    end, {dependfile = target:dependfile(targetfile),
          lastmtime = os.mtime(targetfile),
          changed = target:is_rebuilt(),
          values = depvalues, files = depfiles, dryrun = dryrun})
end
