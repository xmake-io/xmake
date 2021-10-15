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
-- @file        moduledeps.lua
--

-- imports
import("core.project.depend")
import("utils.progress")

-- generate module deps for the given file
function _generate_moduledeps(target, sourcefile, opt)
    local dependfile = target:dependfile(sourcefile)
    depend.on_changed(function ()

        -- trace progress
        progress.show(opt.progress, "${color.build.target}generating.deps %s", sourcefile)

        -- generating deps
        local module_name
        local module_deps
        local sourcecode = io.readfile(sourcefile)
        sourcecode = sourcecode:gsub("//.-\n", "\n")
        sourcecode = sourcecode:gsub("/%*.-%*/", "")
        for _, line in ipairs(sourcecode:split("\n", {plain = true})) do
            if not module_name then
                module_name = line:match("export%s+module%s+(.+)%s*;")
            end
            local module_depname = line:match("import%s+(.+)%s*;")
            if module_depname then
                module_deps = module_deps or {}
                table.insert(module_deps, module_depname)
            end
        end

        -- save depend data
        if module_name then
            io.save(dependfile, {name = module_name, deps = module_deps, file = sourcefile})
        end

    end, {dependfile = dependfile, files = {sourcefile}})
end

-- generate module deps
function generate(target, sourcebatch, opt)
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        _generate_moduledeps(target, sourcefile, opt)
    end
end

