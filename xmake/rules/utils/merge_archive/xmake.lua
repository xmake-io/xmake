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

-- define rule: utils.merge.archive
rule("utils.merge.archive")

    -- set extensions
    set_extensions(".a", ".lib")

    -- on build file
    on_build_file(function (target, sourcefile_lib, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.depend")
        import("core.tool.extractor")
        import("core.project.target", {alias = "project_target"})

        -- get object directory of the archive file
        local objectdir = target:objectfile(sourcefile_lib) .. ".dir"

        -- load dependent info 
        local dependfile = target:dependfile(objectdir)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

        -- need build this object?
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(objectdir)}) then
            local objectfiles = os.files(path.join(objectdir, "**" .. project_target.filename("", "object")))
            table.join2(target:objectfiles(), objectfiles)
            return 
        end

        -- trace progress info
        cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", opt.progress)
        if option.get("verbose") then
            cprint("${dim color.build.object}inserting.$(mode) %s", sourcefile_lib)
            print("extracting %s to %s", sourcefile_lib, objectdir)
        else
            cprint("${color.build.object}inserting.$(mode) %s", sourcefile_lib)
        end

        -- flush io buffer to update progress info
        io.flush()

        -- extract the archive library 
        os.tryrm(objectdir)
        extractor.extract(sourcefile_lib, objectdir)

        -- add objectfiles
        local objectfiles = os.files(path.join(objectdir, "**" .. project_target.filename("", "object")))
        table.join2(target:objectfiles(), objectfiles)

        -- update files to the dependent file
        dependinfo.files = {}
        table.insert(dependinfo.files, sourcefile_lib)
        depend.save(dependinfo, dependfile)
    end)

