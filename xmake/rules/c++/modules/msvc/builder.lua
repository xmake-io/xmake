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
-- @author      ruki, Arthapz
-- @file        msvc/builder.lua
--

-- imports
import("core.base.json")
import("core.base.option")
import("core.base.semver")
import("utils.progress")
import("private.action.build.object", {alias = "objectbuilder"})
import("core.tool.compiler")
import("core.project.config")
import("core.project.depend")
import("private.tools.vstool")
import("support")
import(".mapper")
import(".builder", {inherit = true})

-- get flags for building a module
function _make_modulebuildflags(target, module, opt)

    local ifcoutputflag = support.get_ifcoutputflag(target)
    local ifconlyflag = support.get_ifconlyflag(target)
    local interfaceflag = support.get_interfaceflag(target)
    local internalpartitionflag = support.get_internalpartitionflag(target)

    local bmionly = opt and opt.bmionly

    local flags
    if module.interface or module.implementation then -- named module
        flags = table.join("-TP", module.interface and interfaceflag or internalpartitionflag, bmionly and ifconlyflag or {}, ifcoutputflag, path(module.bmifile))
    else
        flags = {"-TP"}
    end
    return flags
end

function _compile_one_step(target, module, opt)

    -- get flags
    local flags = _make_modulebuildflags(target, module)
    if opt and opt.batchcmds then
        _batchcmds_compile(opt.batchcmds, target, flags, module.sourcefile, module.objectfile)
    else
        _compile(target, flags, module.sourcefile, module.objectfile)
    end
end

function _compile_bmi_step(target, module, opt)

    local ifconlyflag = support.get_ifconlyflag(target)
    if not ifconlyflag then
        _compile_one_step(target, module, opt)
    else
        local flags = _make_modulebuildflags(target, module, {bmionly = true})
        if opt and opt.batchcmds then
            _batchcmds_compile(opt.batchcmds, target, flags, module.sourcefile, module.objectfile)
        else
            _compile(target, flags, module.sourcefile, module.objectfile)
        end
    end
end
    
function _compile_objectfile_step(target, module, opt)

    local flags = _make_modulebuildflags(target, module)
    if opt and opt.batchcmds then
        _batchcmds_compile(opt.batchcmds, target, flags, module.sourcefile, module.objectfile)
    else
        _compile(target, flags, module.sourcefile, module.objectfile)
    end
end

-- get flags for building a headerunit
function _make_headerunitflags(target, headerunit, headertype)

    -- get flags
    local exportheaderflag = support.get_exportheaderflag(target)
    local headernameflag = support.get_headernameflag(target)
    local ifcoutputflag = support.get_ifcoutputflag(target)
    local ifconlyflag = support.get_ifconlyflag(target)
    assert(headernameflag and exportheaderflag, "compiler(msvc): does not support c++ header units!")

    local flags = {"-TP",
                   exportheaderflag,
                   ifcoutputflag,
                   headerunit.bmifile,
                   ifconlyflag or {},
                   headernameflag .. headertype} -- keep it at last flag
    return flags
end

-- do compile
function _compile(target, flags, sourcefile, outputfile)

    local dryrun = option.get("dry-run")
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"})
    flags = table.join(compflags or {}, flags or {})

    -- trace
    if option.get("verbose") then
        if not outputfile then
            print(os.args(table.join(compinst:program(), flags, sourcefile)))
        else
            print(compinst:compcmd(sourcefile, outputfile, {target = target, compflags = flags, sourcekind = "cxx", rawargs = true}))
        end
    end

    -- do compile
    if not dryrun then
        assert(compinst:compile(sourcefile, outputfile or target:objectfile(sourcefile), {target = target, compflags = flags}))
    end
end

-- do compile for batchcmds
-- @note we need to use batchcmds:compilev to translate paths in compflags for generator, e.g. -Ixx
function _batchcmds_compile(batchcmds, target, flags, sourcefile, outputfile)
    opt = opt or {}
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"})
    flags = table.join("/c", compflags or {}, outputfile and "-Fo" .. outputfile or {}, flags or {}, sourcefile or {})
    batchcmds:compilev(flags, {compiler = compinst, sourcekind = "cxx"})
end

-- get module requires flags
-- e.g
-- /reference Foo=build/.gens/Foo/rules/modules/cache/Foo.ifc
-- /headerUnit:angle glm/mat4x4.hpp=Users\arthu\AppData\Local\.xmake\packages\g\glm\0.9.9+8\91454f3ee0be416cb9c7452970a2300f\include\glm\mat4x4.hpp.ifc
--
function _get_requiresflags(target, module)

    local referenceflag = support.get_referenceflag(target)
    local headerunitflag = support.get_headerunitflag(target)

    local name = module.name or module.sourcefile
    local cachekey = target:fullname() .. name

    local requires, requires_changed = is_dependencies_changed(target, module)
    local requiresflags = support.memcache():get2(cachekey, "requiresflags")
    if not requiresflags or requires_changed then
        local deps_flags = {}
        for required, dep in pairs(module.deps) do
            if dep.headerunit then
                required = required .. dep.key
            end
            local dep_module = mapper.get(target, required)
            assert(dep_module, "module dependency %s required for %s not found <%s>", required, name, target:fullname())

            -- aliased headerunit
            local mapflag
            if dep_module.headerunit then
                local type = dep_module.method == "include-angle" and ":angle" or ":quote"
                mapflag = {headerunitflag .. type}
                table.insert(deps_flags, {headerunitflag, dep_module.sourcefile .. "=" .. dep_module.bmifile})
            else
                mapflag = {referenceflag}
            end
            table.insert(mapflag, dep_module.name .. "=" .. dep_module.bmifile)
            table.insert(deps_flags, mapflag)

            -- append deps
            if dep_module.deps then
                local deps = _get_requiresflags(target, dep_module)
                table.join2(deps_flags, deps)
            end
        end

        -- remove duplicates
        requiresflags = {}
        local contains = {}
        table.sort(deps_flags, function(a, b) return a[2] > b[2] end)
        for _, map in ipairs(deps_flags) do
            local name = map[2]:split("=")[1]
            if name and not contains[name] then
                table.insert(requiresflags, map)
                contains[name] = true
            end
        end
        support.memcache():set2(cachekey, "requiresflags", requiresflags)
        support.memcache():set2(cachekey, "oldrequires", requires)
    end
    return requiresflags
end

function _append_requires_flags(target, module)

    local requiresflags = _get_requiresflags(target, module)
    target:fileconfig_add(module.sourcefile, {force = {cxxflags = requiresflags}})
end

function append_requires_flags(target, built_modules)

    -- append requires flags
    for _, sourcefile in ipairs(built_modules) do
        local module = mapper.get(target, sourcefile)
        if module.deps then
            _append_requires_flags(target, module)
        end
    end
end

-- build module file for batchjobs / jobgraph
function make_module_job(target, module, opt)

    local dryrun = option.get("dry-run")

    -- generate and append module mapper file
    local build = should_build(target, module)
    local bmi = opt and opt.bmi
    local objectfile = opt and opt.objectfile

    if build then
        if not dryrun then
            local objectdir = path.directory(module.objectfile)
            if not os.isdir(objectdir) then
                os.mkdir(objectdir)
            end
            if module.bmifile then
                local bmidir = path.directory(module.bmifile)
                if not os.isdir(bmidir) then
                    os.mkdir(bmidir)
                end
            end
        end

        if bmi and objectfile then
            progress.show(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.module.$(mode) %s", target:fullname(), module.name)
            _compile_one_step(target, module)
        elseif bmi then
            progress.show(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.module.bmi.$(mode) %s", target:fullname(), module.name)
            _compile_bmi_step(target, module)
        else
            if module.interface or module.implementation then
                progress.show(opt.progress, "compiling.$(mode) %s", module.sourcefile)
                _compile_objectfile_step(target, module)
            else
                os.tryrm(module.objectfile) -- force rebuild for .cpp files
            end
        end
    end
end

-- build module file for batchcmds
function make_module_buildcmds(target, batchcmds, module, opt)

    -- generate and append module mapper file
    local build = should_build(target, module)
    local bmi = opt and opt.bmi
    local objectfile = opt and opt.objectfile

    if build then
        local objectdir = path.directory(module.objectfile)
        batchcmds:mkdir(objectdir)
        if module.bmifile then
            local bmidir = path.directory(module.bmifile)
            batchcmds:mkdir(bmidir)
        end
        if bmi and objectfile then
            batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.module.$(mode) %s", target:fullname(), module.name)
            _compile_one_step(target, module, {batchcmds = batchcmds})
        elseif bmi then
            batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.module.bmi.$(mode) %s", target:fullname(), module.name)
            _compile_bmi_step(target, module, {batchcmds = batchcmds})
        else
            if module.interface or module.implementation then
                batchcmds:show_progress(opt.progress, "compiling.$(mode) %s", module.sourcefile)
                _compile_objectfile_step(target, module, {batchcmds = batchcmds})
            else
                batchcmds:rm(module.objectfile) -- force rebuild for .cpp files
            end
        end
    end
    batchcmds:add_depfiles(module.sourcefile)
    return os.mtime(module.objectfile)
end

-- build headerunit file for batchjobs / jobgraph
function make_headerunit_job(target, headerunit, opt)

    local build = should_build(target, headerunit)
    if build then
        local name = headerunit.unique and path.filename(headerunit.name) or headerunit.name
        local headertype = (headerunit.method == "include-angle") and ":angle" or ":quote"
        progress.show(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.headerunit.$(mode) %s", target:fullname(), name)
        _compile(target, _make_headerunitflags(target, headerunit, headertype), (headertype == ":angle") and headerunit.name or headerunit.sourcefile)
    end
end

-- build headerunit file for batchcmds
function make_headerunit_buildcmds(target, batchcmds, headerunit, opt)
    
    local compinst = compiler.load("cxx", {target = target})
    local compflags = compinst:compflags({sourcefile = headerunit.sourcefile, target = target, sourcekind = "cxx"})
    local depvalues = {compinst:program(), compflags}

    local build = should_build(target, headerunit)
    if build then
        local name = headerunit.unique and path.filename(headerunit.name) or headerunit.name
        local headertype = (headerunit.method == "include-angle") and ":angle" or ":quote"
        batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.headerunit.$(mode) %s", target:fullname(), name)
        _batchcmds_compile(batchcmds, target, _make_headerunitflags(target, headerunit, headertype), (headertype == ":angle") and headerunit.name or headerunit.sourcefile)
        batchcmds:add_depfiles(headerunit.sourcefile)
    end
    batchcmds:add_depvalues(depvalues)
end
