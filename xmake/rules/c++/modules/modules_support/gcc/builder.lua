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
-- @file        gcc/builder.lua
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
import("compiler_support")
import(".builder", {inherit = true})

-- get flags for building a module
function _make_modulebuildflags(target, opt)

    local flags = {"-x", "c++", "-c"}
    if opt.batchcmds then
        table.join2(flags, "-o", target:objectfile(opt.sourcefile), opt.sourcefile)
    end

    return flags
end

-- get flags for building a headerunit
function _make_headerunitflags(target, headerunit, headerunit_mapper, opt)

    -- get flags
    local module_headerflag = compiler_support.get_moduleheaderflag(target)
    local module_onlyflag = compiler_support.get_moduleonlyflag(target)
    local module_mapperflag = compiler_support.get_modulemapperflag(target)
    assert(module_headerflag and module_onlyflag, "compiler(gcc): does not support c++ header units!")

    local local_directory = (headerunit.type == ":quote") and {"-I" .. path.directory(path.normalize(headerunit.path))} or {}

    local headertype = (headerunit.type == ":angle") and "system" or "user"

    local flags = table.join(local_directory, {module_mapperflag .. headerunit_mapper,
                                        module_headerflag .. headertype,
                                        module_onlyflag,
                                        "-xc++-header",
                                        "-c"})
    if opt.batchcmds then
       table.join2(flags, {"-o", opt.bmifile, path.filename(headerunit.path)})
    end

    return flags
end

-- do compile
function _compile(target, flags, sourcefile, outputfile)

    local dryrun = option.get("dry-run")
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
    local flags = table.join(compflags or {}, flags)

    -- trace
    if option.get("verbose") then
        print(compinst:compcmd(sourcefile, outputfile, {compflags = flags, rawargs = true}))
    end


    if not dryrun then
        -- do compile
        compinst:compile(sourcefile, outputfile, {compflags = flags})
    end
end

-- do compile for batchcmds
-- @note we need to use batchcmds:compilev to translate paths in compflags for generator, e.g. -Ixx
function _batchcmds_compile(batchcmds, target, flags, sourcefile)

    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
    local flags = table.join(compflags or {}, flags)

    batchcmds:compilev(flags, {compiler = compinst, sourcekind = "cxx"})
end

function _module_map_cachekey(target)

    local mode = config.mode()
    return target:name() .. "module_mapper" .. (mode or "")
end

-- generate a module mapper file for build a headerunit
function _generate_headerunit_modulemapper_file(module)

    local path = os.tmpfile()
    local mapper_file = io.open(path, "wb")

    mapper_file:write("root " .. os.projectdir())
    mapper_file:write("\n")

    mapper_file:write(mapper_file, module.name:replace("\\", "/") .. " " .. module.bmifile:replace("\\", "/"))
    mapper_file:write("\n")

    mapper_file:close()

    return path

end

function _get_maplines(target, module)
    local maplines = {}

    local m_name, m = compiler_support.get_provided_module(module)
    if m then
        table.insert(maplines, m_name .. " " .. compiler_support.get_bmi_path(m.bmi))
    end

    for required, _ in pairs(module.requires) do
        local dep_module
        local dep_target
        for _, dep in ipairs(target:orderdeps()) do
            dep_module = get_from_target_mapper(dep, required)
            if dep_module then
                dep_target = dep
                break
            end
        end

        -- if not in target dep
        if not dep_module then
            dep_module = get_from_target_mapper(target, required)
            if dep_module then
                dep_target = target
            end
        end

        assert(dep_module, "module dependency %s required for %s not found", required, name)

        local bmifile = dep_module.bmi
        local mapline
        -- aliased headerunit
        if dep_module.aliasof then
            local aliased = get_from_target_mapper(target, dep_module.aliasof)
            bmifile = aliased.bmi
            mapline = dep_module.headerunit.path:replace("\\", "/") .. " " .. bmifile:replace("\\", "/")
        -- headerunit
        elseif dep_module.headerunit then
            mapline = dep_module.headerunit.path:replace("\\", "/") .. " " .. bmifile:replace("\\", "/")
        -- named module
        else
            mapline = required .. " " .. bmifile:replace("\\", "/")
        end
        table.insert(maplines, mapline)

        -- append deps
        if dep_module.opt and dep_module.opt.deps then
            local deps = _get_maplines(dep_target, { name = dep_module.name, bmi = bmifile, requires = dep_module.opt.deps })
            table.join2(maplines, deps)
        end
    end

    -- remove duplicates
    return table.unique(maplines)
end

-- generate a module mapper file for build a module
-- e.g
-- /usr/include/c++/11/iostream build/.gens/stl_headerunit/linux/x86_64/release/stlmodules/cache/iostream.gcm
-- hello build/.gens/stl_headerunit/linux/x86_64/release/rules/modules/cache/hello.gcm
--
function _generate_modulemapper_file(target, module)

    local maplines = _get_maplines(target, module)

    local path = os.tmpfile()
    local mapper_file = io.open(path, "wb")

    mapper_file:write("root " .. os.projectdir():replace("\\", "/"))
    mapper_file:write("\n")

    for _, mapline in ipairs(maplines) do
        mapper_file:write(mapline)
        mapper_file:write("\n")
    end

    mapper_file:close()

    return path
end

-- populate module map 
function populate_module_map(target, modules)

    -- append all modules
    for _, module in pairs(modules) do
        local name, provide = compiler_support.get_provided_module(module)
        if provide then
            add_module_to_target_mapper(target, name, provide.sourcefile, compiler_support.get_bmi_path(provide.bmi))
        end
    end

    -- then update their deps
    for _, module in pairs(modules) do
        local name, provide = compiler_support.get_provided_module(module)
        if provide then
            local bmifile = compiler_support.get_bmi_path(provide.bmi)
            add_module_to_target_mapper(target, name, provide.sourcefile, bmifile, {deps = module.requires})
        end
    end
end

-- get defines for a module
function get_module_required_defines(target, sourcefile)
    local compinst = compiler.load("cxx", {target = target})
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
    local defines

    for _, flag in ipairs(compflags) do
        if flag:startswith("-D") then
            defines = defines or {}
            table.insert(defines, flag:sub(3))
        end
    end

    return defines
end

-- build module file for batchjobs
function make_module_build_job(target, batchjobs, job_name, deps, opt)

    local name, provide, _ = compiler_support.get_provided_module(opt.module)
    local bmifile = provide and compiler_support.get_bmi_path(provide.bmi)
    local module_mapperflag = compiler_support.get_modulemapperflag(target)

    return {
        name = job_name,
        deps = deps,
        sourcefile = opt.cppfile,
        job = batchjobs:newjob(name or opt.cppfile, function(index, total)

            local compinst = compiler.load("cxx", {target = target})
            local compflags = compinst:compflags({sourcefile = opt.cppfile, target = target})

            -- generate and append module mapper file
            local module_mapper
            if provide or opt.module.requires then
                module_mapper = _generate_modulemapper_file(target, opt.module)
                target:fileconfig_add(opt.cppfile, {force = {cxxflags = {module_mapperflag .. module_mapper}}})
            end

            local dependfile = target:dependfile(bmifile or opt.objectfile)
            local dependinfo = depend.load(dependfile) or {}
            dependinfo.files = {}
            local depvalues = {compinst:program(), compflags}

            if opt.build then
                -- compile if it's a named module
                if provide or compiler_support.has_module_extension(opt.cppfile) then
                    progress.show((index * 100) / total, "${color.build.target}<%s> ${clear}${color.build.object}compiling.module.$(mode) %s", target:name(), name or opt.cppfile)
                    if option.get("diagnosis") then
                        print("mapper file --------\n%s--------", io.readfile(module_mapper))
                    end

                    local flags = _make_modulebuildflags(target, opt)
                    _compile(target, flags, opt.cppfile, opt.objectfile)
                    os.tryrm(module_mapper)
                end
            end
            table.insert(dependinfo.files, opt.cppfile)
            dependinfo.values = depvalues
            depend.save(dependinfo, dependfile)
        end)}
end

-- build module file for batchcmds
function make_module_build_cmds(target, batchcmds, opt)

    local name, provide, _ = compiler_support.get_provided_module(opt.module)
    local module_mapperflag = compiler_support.get_modulemapperflag(target)

    -- generate and append module mapper file
    local module_mapper
    if provide or opt.module.requires then
        module_mapper = _generate_modulemapper_file(target, opt.module)
        target:fileconfig_add(opt.cppfile, {force = {cxxflags = {module_mapperflag .. module_mapper}}})
    end

    if opt.build then
        -- compile if it's a named module
        if provide or compiler_support.has_module_extension(opt.cppfile) then
            batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.module.$(mode) %s", target:name(), name or opt.cppfile)
            if option.get("diagnosis") then
                batchcmds:print("mapper file: %s", io.readfile(module_mapper))
            end
            batchcmds:mkdir(path.directory(opt.objectfile))

            _batchcmds_compile(batchcmds, target, _make_modulebuildflags(target, {batchcmds = true, sourcefile = opt.cppfile}), opt.cppfile)
        end
    end

    batchcmds:add_depfiles(opt.cppfile)

    return os.mtime(opt.objectfile)
end

-- build headerunit file for batchjobs
function make_headerunit_build_job(target, job_name, batchjobs, headerunit, bmifile, outputdir, opt)

    local _headerunit = headerunit
    _headerunit.path = headerunit.type == ":quote" and "./" .. path.relative(headerunit.path) or headerunit.path
    local already_exists = add_headerunit_to_target_mapper(target, _headerunit, bmifile)
    if not already_exists then
        return {
            name = job_name,
            sourcefile = headerunit.path,
            job = batchjobs:newjob(job_name, function(index, total)
                if not os.isdir(outputdir) then
                    os.mkdir(outputdir)
                end

                local compinst = compiler.load("cxx", {target = target})
                local compflags = compinst:compflags({sourcefile = headerunit.path, target = target})

                local dependfile = target:dependfile(bmifile)
                local dependinfo = depend.load(dependfile) or {}
                dependinfo.files = {}
                local depvalues = {compinst:program(), compflags}

                if opt.build then
                    local headerunit_mapper = _generate_headerunit_modulemapper_file({name = path.normalize(headerunit.path), bmifile = bmifile})

                    progress.show((index * 100) / total, "${color.build.target}<%s> ${clear}${color.build.object}compiling.headerunit.$(mode) %s", target:name(), headerunit.name)
                    if option.get("diagnosis") then
                        print("mapper file:\n%s", io.readfile(headerunit_mapper))
                    end
                    _compile(target, _make_headerunitflags(target, headerunit, headerunit_mapper, opt), path.translate(path.filename(headerunit.name)), bmifile)
                    os.tryrm(headerunit_mapper)
                end

                table.insert(dependinfo.files, headerunit.path)
                dependinfo.values = depvalues
                depend.save(dependinfo, dependfile)
            end)}
    end
end

-- build headerunit file for batchcmds
function make_headerunit_build_cmds(target, batchcmds, headerunit, bmifile, outputdir, opt)

    local headerunit_mapper = _generate_headerunit_modulemapper_file({name = path.normalize(headerunit.path), bmifile = bmifile})
    batchcmds:mkdir(outputdir)

    local _headerunit = headerunit
    _headerunit.path = headerunit.type == ":quote" and "./" .. path.relative(headerunit.path) or headerunit.path
    add_headerunit_to_target_mapper(target, _headerunit, bmifile)

    if opt.build then
        local name = headerunit.unique and headerunit.name or headerunit.path
        batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.headerunit.$(mode) %s", target:name(), name)
        if option.get("diagnosis") then
            batchcmds:print("mapper file:\n%s", io.readfile(headerunit_mapper))
        end
        _batchcmds_compile(batchcmds, target, _make_headerunitflags(target, headerunit, headerunit_mapper, {batchcmds = true, bmifile = bmifile}))
    end

    batchcmds:rm(headerunit_mapper)
    batchcmds:add_depfiles(headerunit.path)
    return os.mtime(bmifile)
end

