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
import("core.base.hashset")

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

        -- get module name
        local proto_rootdir = opt.proto_rootdir
        local module_name = path.filename(sourcefile)
        if proto_rootdir then
            local name = path.relative(sourcefile, proto_rootdir)
            if name then
                module_name = name
            end
        end

        -- generating deps
        local module_deps
        local sourcecode = io.readfile(sourcefile)
        sourcecode = sourcecode:gsub("//.-\n", "\n")
        sourcecode = sourcecode:gsub("/%*.-%*/", "")
        for _, line in ipairs(sourcecode:split("\n", {plain = true})) do
            local module_depname = line:match("import%s+\"(.+)\"%s*;")
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

-- build batch jobs with deps
function _build_batchjobs_with_deps(moduledeps, batchjobs, rootjob, jobrefs, moduleinfo)
    local targetjob_ref = jobrefs[moduleinfo.name]
    if targetjob_ref then
        batchjobs:add(targetjob_ref, rootjob)
    else
        local modulejob = batchjobs:add(moduleinfo.job, rootjob)
        if modulejob then
            jobrefs[moduleinfo.name] = modulejob
            for _, depname in ipairs(moduleinfo.deps) do
                local dep = moduledeps[depname]
                if dep then -- maybe nil, e.g. `import <string>;`
                    _build_batchjobs_with_deps(moduledeps, batchjobs, modulejob, jobrefs, dep)
                end
            end
        end
    end
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
                if moduleinfo then
                    moduledeps = moduledeps or {}
                    moduledeps[moduleinfo.name] = moduleinfo
                end
            end
        end
    end

    -- get moduledeps with file map
    local moduledeps_files = {}
    for _, moduleinfo in pairs(moduledeps) do
        moduledeps_files[moduleinfo.file] = moduleinfo
    end
    return moduledeps, moduledeps_files
end

-- build batch jobs
function build_batchjobs(moduledeps, batchjobs, rootjob)
    local depset = hashset.new()
    for _, moduleinfo in pairs(moduledeps) do
        assert(moduleinfo.job)
        for _, depname in ipairs(moduleinfo.deps) do
            depset:insert(depname)
        end
    end
    local moduledeps_root = {}
    for _, moduleinfo in pairs(moduledeps) do
        if not depset:has(moduleinfo.name) then
            table.insert(moduledeps_root, moduleinfo)
        end
    end
    local jobrefs = {}
    for _, moduleinfo in pairs(moduledeps_root) do
        _build_batchjobs_with_deps(moduledeps, batchjobs, rootjob, jobrefs, moduleinfo)
    end
end
