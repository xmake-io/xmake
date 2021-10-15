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
-- @file        module_parser.lua
--

-- imports
import("core.project.depend")

-- get depend file of module source file
function _get_dependfile_of_modulesource(target, sourcefile)
    return target:dependfile(sourcefile)
end

-- get depend file of module object file, compiler will rewrite it
function _get_dependfile_of_moduleobject(target, sourcefile)
    local objectfile = target:objectfile(sourcefile)
    return target:dependfile(objectfile)
end

-- generate module deps for the given file
function _generate_moduledeps(target, sourcefile, opt)
    local dependfile = _get_dependfile_of_modulesource(target, sourcefile)
    depend.on_changed(function ()

        -- trace
        vprint("generating.moduledeps %s", sourcefile)

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
            local dependinfo = {moduleinfo = {name = module_name, deps = module_deps, file = sourcefile}}
            return dependinfo
        end

    end, {dependfile = dependfile, files = {sourcefile}})
end

-- generate module deps
function generate(target, sourcebatch, opt)
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        _generate_moduledeps(target, sourcefile, opt)
    end
end

-- load module deps
function load(target, sourcebatch, opt)

    -- do generate first
    generate(target, sourcebatch, opt)

    -- load deps
    local moduledeps
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local dependfile = _get_dependfile_of_modulesource(target, sourcefile)
        if os.isfile(dependfile) then
            local data = io.load(dependfile)
            if data then
                local moduleinfo = data.moduleinfo
                moduledeps = moduledeps or {}
                moduledeps[moduleinfo.name] = moduleinfo
            end
        end
    end
    return moduledeps
end

-- build module deps
function build(moduledeps)
    local moduledeps_files = {}
    for _, moduledep in pairs(moduledeps) do
        if moduledep.deps then
            for _, depname in ipairs(moduledep.deps) do
                local dep = moduledeps[depname]
                if dep then
                    dep.parents = dep.parents or {}
                    table.insert(dep.parents, moduledep)
                end
            end
        end
        moduledeps_files[moduledep.file] = moduledep
    end
    return moduledeps_files
end
