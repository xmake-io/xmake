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
-- @file        xmake.lua
--

-- define rule: device-link
rule("cuda.device_link")

    -- after load
    after_load(function (target)

        -- get cuda directory 
        local cuda_dir = assert(get_config("cuda"), "Cuda SDK directory not found!")

        -- add links
        target:add("links", "cudart")
        target:add("linkdirs", path.join(cuda_dir, "lib"))
        target:add("rpathdirs", path.join(cuda_dir, "lib"))
    end)

    -- before link
    before_link(function (target, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.config")
        import("core.project.depend")
        import("core.tool.linker")

        -- load linker instance
        local linkinst = linker.load("gpucode", "cu", {target = target})

        -- get link flags
        local linkflags = linkinst:linkflags({target = target, configs = {force = {culdflags = "-dlink"}}})

        -- get target file
        local targetfile = target:objectfile(path.join(".cuda", "devlink", target:basename() .. "_gpucode.cu"))

        -- get object files
        local objectfiles = nil
        for sourcekind, sourcebatch in pairs(target:sourcebatches()) do
            if sourcekind == "cu" then
                objectfiles = sourcebatch.objectfiles
            end
        end
        if not objectfiles then
            return
        end

        -- insert gpucode.o to the object files
        table.insert(target:objectfiles(), targetfile)

        -- load dependent info 
        local dependfile = target:dependfile(targetfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

        -- need build this target?
        local depfiles = objectfiles
        local depvalues = {nvcc, linkflags}
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(target:targetfile()), values = depvalues, files = depfiles}) then
            return 
        end

        -- is verbose?
        local verbose = option.get("verbose")

        -- trace progress info
        cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", opt.progress)
        if verbose then
            cprint("${dim color.build.target}devlinking.$(mode) %s", path.filename(targetfile))
        else
            cprint("${color.build.target}devlinking.$(mode) %s", path.filename(targetfile))
        end

        -- trace verbose info
        if verbose then
            print(linkinst:linkcmd(objectfiles, targetfile, {linkflags = linkflags}))
        end

        -- flush io buffer to update progress info
        io.flush()

        -- link it
        assert(linkinst:link(objectfiles, targetfile, {linkflags = linkflags}))

        -- update files and values to the dependent file
        dependinfo.files  = depfiles
        dependinfo.values = depvalues
        depend.save(dependinfo, dependfile)
    end)

