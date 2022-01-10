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
-- @file        xmake.lua
--

-- define rule: utils.merge.object
rule("utils.merge.object")

    -- set extensions
    set_extensions(".o", ".obj")

    -- on build file
    on_build_file(function (target, sourcefile_obj, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.depend")
        import("utils.progress")

        -- get object file
        local objectfile = target:objectfile(sourcefile_obj)

        -- add objectfile
        table.insert(target:objectfiles(), objectfile)

        -- load dependent info
        local dependfile = target:dependfile(objectfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

        -- need build this object?
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(objectfile)}) then
            return
        end

        -- trace progress info
        progress.show(opt.progress, "${color.build.object}inserting.$(mode) %s", sourcefile_obj)

        -- insert this object file
        os.vcp(sourcefile_obj, objectfile)

        -- update files to the dependent file
        dependinfo.files = {}
        table.insert(dependinfo.files, sourcefile_obj)
        depend.save(dependinfo, dependfile)
    end)

