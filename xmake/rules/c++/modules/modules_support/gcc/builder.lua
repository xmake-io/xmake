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

-- get flags for building a headerunit
function _make_headerunitflags(target, headerunit, headerunit_mapper)
    local module_headerflag = compiler_support.get_moduleheaderflag(target)
    local module_onlyflag = compiler_support.get_moduleonlyflag(target)
    local module_mapperflag = compiler_support.get_modulemapperflag(target)
    assert(module_headerflag and module_onlyflag, "compiler(gcc): does not support c++ header units!")

    local local_directory = (headerunit.type == ":quote") and {"-I" .. path.directory(path.normalize(headerunit.path))} or {}
    local headertype = (headerunit.type == ":angle") and "system" or "user"
    local flags = table.join(local_directory, {module_mapperflag .. headerunit_mapper,
                                               module_headerflag .. headertype,
                                               module_onlyflag,
                                               "-xc++-header"})
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
        print(compinst:compcmd(sourcefile, outputfile, {target = target, compflags = flags, rawargs = true}))
    end

    -- do compile
    if not dryrun then
        assert(compinst:compile(sourcefile, outputfile, {target = target, compflags = flags}))
    end
end

-- do compile for batchcmds
-- @note we need to use batchcmds:compilev to translate paths in compflags for generator, e.g. -Ixx
function _batchcmds_compile(batchcmds, target, flags, sourcefile, outputfile)
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
    local flags = table.join("-c", compflags or {}, flags, {"-o", outputfile, sourcefile})
    batchcmds:compilev(flags, {compiler = compinst, sourcekind = "cxx"})
end

function _module_map_cachekey(target)
    local mode = config.mode()
    return target:name() .. "module_mapper" .. (mode or "")
end

-- generate a module mapper file for build a headerunit
function _generate_headerunit_modulemapper_file(module)
    local mapper_path = os.tmpfile()
    local mapper_file = io.open(mapper_path, "wb")
    mapper_file:write("root " .. path.unix(os.projectdir()))
    mapper_file:write("\n")
    mapper_file:write(mapper_file, path.unix(module.name) .. " " .. path.unix(module.bmifile))
    mapper_file:write("\n")
    mapper_file:close()
    return mapper_path
end

function _get_maplines(target, module)
    local maplines = {}
    local m_name, m, _ = compiler_support.get_provided_module(module)
    if m then
        table.insert(maplines, m_name .. " " .. compiler_support.get_bmi_path(m.bmi))
    end
    for required, _ in table.orderpairs(module.requires) do
        local dep_module = get_from_target_mapper(target, required)
        assert(dep_module, "module dependency %s required for %s not found", required, m_name or module.cppfile)

        local bmifile = dep_module.bmi
        local mapline
        -- aliased headerunit
        if dep_module.aliasof then
            local aliased = get_from_target_mapper(target, dep_module.aliasof)
            bmifile = aliased.bmi
            mapline = path.unix(dep_module.headerunit.path) .. " " .. path.unix(bmifile)
        -- headerunit
        elseif dep_module.headerunit then
            mapline = path.unix(dep_module.headerunit.path) .. " " .. path.unix(bmifile)
        -- named module
        else
            mapline = required .. " " .. path.unix(bmifile)
        end
        table.insert(maplines, mapline)

        -- append deps
        if dep_module.opt and dep_module.opt.deps then
            local deps = _get_maplines(target, {name = dep_module.name, bmi = bmifile, requires = dep_module.opt.deps})
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
function _generate_modulemapper_file(target, module, cppfile)
    local maplines = _get_maplines(target, module)
    local mapper_path = path.join(os.tmpdir(), target:name():replace(" ", "_"), name or cppfile:replace(" ", "_"))
    local mapper_content = {}
    table.insert(mapper_content, "root " .. path.unix(os.projectdir()))
    for _, mapline in ipairs(maplines) do
        table.insert(mapper_content, mapline)
    end
    mapper_content = table.concat(mapper_content, "\n") .. "\n"
    if not os.isfile(mapper_path) or io.readfile(mapper_path, {encoding = "binary"}) ~= mapper_content then
        io.writefile(mapper_path, mapper_content, {encoding = "binary"})
    end
    return mapper_path
end

-- populate module map
function populate_module_map(target, modules)
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
function make_module_buildjobs(target, batchjobs, job_name, deps, opt)

    local name, provide, _ = compiler_support.get_provided_module(opt.module)
    local bmifile = provide and compiler_support.get_bmi_path(provide.bmi)
    local module_mapperflag = compiler_support.get_modulemapperflag(target)

    return {
        name = job_name,
        deps = table.join(target:name() .. "_populate_module_map", deps),
        sourcefile = opt.cppfile,
        job = batchjobs:newjob(name or opt.cppfile, function(index, total, jobopt)
            local mapped_bmi
            if provide and compiler_support.memcache():get2(target:name() .. name, "reuse") then
                mapped_bmi = get_from_target_mapper(target, name).bmi
            end

            -- generate and append module mapper file
            local module_mapper
            if provide or opt.module.requires then
                module_mapper = _generate_modulemapper_file(target, opt.module, opt.cppfile)
                target:fileconfig_add(opt.cppfile, {force = {cxxflags = {module_mapperflag .. module_mapper}}})
            end

            local dependfile = target:dependfile(bmifile or opt.objectfile)
            local build, dependinfo = should_build(target, opt.cppfile, bmifile, {name = name, objectfile = opt.objectfile, requires = opt.module.requires})

            -- needed to detect rebuild of dependencies
            if provide and build then
                mark_build(target, name)
            end

            if build then
                -- compile if it's a named module
                if provide or compiler_support.has_module_extension(opt.cppfile) then
                    local fileconfig = target:fileconfig(opt.cppfile)
                    local public = fileconfig and fileconfig.public
                    local external = fileconfig and fileconfig.external
                    local from_moduleonly = external and external.moduleonly
                    local bmifile = mapped_bmi or bmifile
                    local flags = {"-x", "c++"}
                    local sourcefile
                    if external and not from_moduleonly then
                        if not mapped_bmi then
                            progress.show(jobopt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.bmi.$(mode) %s", target:name(), name or opt.cppfile)
                            local module_onlyflag = compiler_support.get_moduleonlyflag(target)
                            table.insert(flags, module_onlyflag)
                            sourcefile = opt.cppfile
                        end
                    else
                        progress.show(jobopt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.module.$(mode) %s", target:name(), name or opt.cppfile)
                        sourcefile = opt.cppfile
                    end
                    if option.get("diagnosis") then
                        print("mapper file --------\n%s--------", io.readfile(module_mapper))
                    end
                    if sourcefile then
                        _compile(target, flags, sourcefile, opt.objectfile)
                    end
                    os.tryrm(module_mapper)
                else
                    os.tryrm(opt.objectfile) -- force rebuild for .cpp files
                end
                depend.save(dependinfo, dependfile)
            end
        end)}
end

-- build module file for batchcmds
function make_module_buildcmds(target, batchcmds, opt)

    local name, provide, _ = compiler_support.get_provided_module(opt.module)
    local bmifile = provide and compiler_support.get_bmi_path(provide.bmi)
    local module_mapperflag = compiler_support.get_modulemapperflag(target)

    local mapped_bmi
    if provide and compiler_support.memcache():get2(target:name() .. name, "reuse") then
        mapped_bmi = get_from_target_mapper(target, name).bmi
    end

    -- generate and append module mapper file
    local module_mapper
    if provide or opt.module.requires then
        module_mapper = _generate_modulemapper_file(target, opt.module, opt.cppfile)
        target:fileconfig_add(opt.cppfile, {force = {cxxflags = {module_mapperflag .. module_mapper}}})
    end

    -- compile if it's a named module
    if provide or compiler_support.has_module_extension(opt.cppfile) then
        batchcmds:mkdir(path.directory(opt.objectfile))
        local fileconfig = target:fileconfig(opt.cppfile)
        local public = fileconfig and fileconfig.public
        local external = fileconfig and fileconfig.external
        local from_moduleonly = external and external.moduleonly
        local bmifile = mapped_bmi or bmifile
        local flags = {"-x", "c++"}
        local sourcefile
        if external and not from_moduleonly then
            if not mapped_bmi then
                batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.bmi.$(mode) %s", target:name(), name or opt.cppfile)
                local module_onlyflag = compiler_support.get_moduleonlyflag(target)
                table.insert(flags, module_onlyflag)
                sourcefile = opt.cppfile
            end
        else
            batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.module.$(mode) %s", target:name(), name or opt.cppfile)
            sourcefile = opt.cppfile
        end
        if option.get("diagnosis") then
            batchcmds:print("mapper file: %s", io.readfile(module_mapper))
        end
        if sourcefile then
            _batchcmds_compile(batchcmds, target, flags, sourcefile, opt.objectfile)
        end
        batchcmds:rm(module_mapper)
    else
        batchcmds:rm(opt.objectfile) -- force rebuild for .cpp files
    end
    batchcmds:add_depfiles(opt.cppfile)
    return os.mtime(opt.objectfile)
end

-- build headerunit file for batchjobs
function make_headerunit_buildjobs(target, job_name, batchjobs, headerunit, bmifile, outputdir, opt)

    local _headerunit = headerunit
    _headerunit.path = headerunit.type == ":quote" and "./" .. path.relative(headerunit.path) or headerunit.path
    local already_exists = add_headerunit_to_target_mapper(target, _headerunit, bmifile)
    if not already_exists then
        return {
            name = job_name,
            sourcefile = headerunit.path,
            job = batchjobs:newjob(job_name, function(index, total, jobopt)
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
                    progress.show(jobopt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.headerunit.$(mode) %s", target:name(), headerunit.name)
                    if option.get("diagnosis") then
                        print("mapper file:\n%s", io.readfile(headerunit_mapper))
                    end
                    _compile(target,
                        _make_headerunitflags(target, headerunit, headerunit_mapper, opt),
                        path.translate(path.filename(headerunit.name)), bmifile)
                    os.tryrm(headerunit_mapper)
                end

                table.insert(dependinfo.files, headerunit.path)
                dependinfo.values = depvalues
                depend.save(dependinfo, dependfile)
            end)}
    end
end

-- build headerunit file for batchcmds
function make_headerunit_buildcmds(target, batchcmds, headerunit, bmifile, outputdir, opt)

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
        _batchcmds_compile(batchcmds, target, _make_headerunitflags(target, headerunit, headerunit_mapper), bmifile)
    end

    batchcmds:rm(headerunit_mapper)
    batchcmds:add_depfiles(headerunit.path)
    return os.mtime(bmifile)
end

