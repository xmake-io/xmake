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
-- @file        clang/builder.lua
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

function _compile_one_step(target, bmifile, sourcefile, objectfile, opt)
    local module_outputflag = compiler_support.get_moduleoutputflag(target)
    if opt.is_mapped_bmi then
        -- get flags
        if module_outputflag then
            local flags = table.join(opt.std and {"-Wno-include-angled-in-module-purview", "-Wno-reserved-module-identifier"} or {})
            if opt and opt.batchcmds then
                _batchcmds_compile(opt.batchcmds, target, flags, bmifile, objectfile)
            else
                _compile(target, flags, bmifile, objectfile)
            end
        else
            _compile_objectfile_step(target, bmifile, sourcefile, objectfile, opt)
        end
    else
        -- get flags
        if module_outputflag then
            local flags = table.join({"-x", "c++-module", module_outputflag .. bmifile}, opt.std and {"-Wno-include-angled-in-module-purview", "-Wno-reserved-module-identifier"} or {})
            if opt and opt.batchcmds then
                _batchcmds_compile(opt.batchcmds, target, flags, sourcefile, objectfile)
            else
                _compile(target, flags, sourcefile, objectfile)
            end
        else
            _compile_bmi_step(target, bmifile, sourcefile, opt)
            _compile_objectfile_step(target, bmifile, sourcefile, objectfile, opt)
        end
    end
end

function _compile_bmi_step(target, bmifile, sourcefile, opt)
    local flags = table.join({"-x", "c++-module", "--precompile"}, opt.std and {"-Wno-include-angled-in-module-purview", "-Wno-reserved-module-identifier"} or {})
    if opt and opt.batchcmds then
        _batchcmds_compile(opt.batchcmds, target, flags, sourcefile, bmifile)
    else
        _compile(target, flags, sourcefile, bmifile)
    end
end

function _compile_objectfile_step(target, bmifile, sourcefile, objectfile, opt)
    _compile(target, {}, sourcefile, objectfile, {bmifile = bmifile})
    if opt and opt.batchcmds then
        _batchcmds_compile(opt.batchcmds, target, {}, sourcefile, objectfile, {bmifile = bmifile})
    else
        _compile(target, {}, sourcefile, objectfile, {bmifile = bmifile})
    end
end

-- get flags for building a headerunit
function _make_headerunitflags(target, headerunit, bmifile)

    local module_headerflag = compiler_support.get_moduleheaderflag(target)
    assert(module_headerflag, "compiler(clang): does not support c++ header units!")

    local local_directory = (headerunit.type == ":quote") and {"-I" .. path.directory(headerunit.path)} or {}
    local headertype = (headerunit.type == ":angle") and "system" or "user"
    local flags = table.join(local_directory, {"-xc++-header", "-Wno-everything", module_headerflag .. headertype})
    return flags
end

-- do compile
function _compile(target, flags, sourcefile, outputfile, opt)

    opt = opt or {}
    local dryrun = option.get("dry-run")
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
    local flags = table.join(compflags or {}, flags)

    -- trace
    if option.get("verbose") then
        print(compinst:compcmd(opt.bmifile or sourcefile, outputfile, {target = target, compflags = flags, rawargs = true}))
    end

    -- do compile
    if not dryrun then
        assert(compinst:compile(opt.bmifile or sourcefile, outputfile, {target = target, compflags = flags}))
    end
end

-- do compile for batchcmds
-- @note we need to use batchcmds:compilev to translate paths in compflags for generator, e.g. -Ixx
function _batchcmds_compile(batchcmds, target, flags, sourcefile, outputfile, opt)
    opt = opt or {}
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
    flags = table.join("-c", compflags or {}, flags, {"-o", outputfile, opt.bmifile or sourcefile})
    batchcmds:compilev(flags, {compiler = compinst, sourcekind = "cxx"})
end

-- get module requires flags
-- e.g
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/foo.pcm
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/iostream.pcm
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/bar.hpp.pcm
-- on LLVM >= 16
-- -fmodule-file=foo=build/.gens/Foo/rules/modules/cache/foo.pcm
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/iostream.pcm
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/bar.hpp.pcm
--
function _get_requiresflags(target, module, opt)

    local modulefileflag = compiler_support.get_modulefileflag(target)
    local name = module.name
    local cachekey = target:name() .. name

    local requires, requires_changed = is_dependencies_changed(target, module)
    local requiresflags = compiler_support.memcache():get2(cachekey, "requiresflags")
    if not requiresflags or requires_changed then
        requiresflags = {}
        for required in requires:orderitems() do
            local dep_module = get_from_target_mapper(target, required)
            assert(dep_module, "module dependency %s required for %s not found", required, name)

            -- aliased headerunit
            local bmifile = dep_module.bmi
            if dep_module.aliasof then
                local aliased = get_from_target_mapper(target, dep_module.aliasof)
                bmifile = aliased.bmi
            end
            local mapflag = (dep_module.opt and dep_module.opt.namedmodule) and format("%s%s=%s", modulefileflag, required, bmifile) or modulefileflag .. bmifile
            table.insert(requiresflags, mapflag)

            -- append deps
            if dep_module.opt and dep_module.opt.deps then
                local deps = _get_requiresflags(target, {name = dep_module.name or dep_module.sourcefile, bmi = bmifile, requires = dep_module.opt.deps})
                table.join2(requiresflags, deps)
            end
        end
        requiresflags = table.unique(requiresflags)
        compiler_support.memcache():set2(cachekey, "requiresflags", requiresflags)
        compiler_support.memcache():set2(cachekey, "oldrequires", requires)
    end
    return requiresflags
end

function _append_requires_flags(target, module, name, cppfile, bmifile, opt)
    local cxxflags = {}
    local requiresflags = _get_requiresflags(target, {name = (name or cppfile), bmi = bmifile, requires = module.requires})
    for _, flag in ipairs(requiresflags) do
        -- we need to wrap flag to support flag with space
        if type(flag) == "string" and flag:find(" ", 1, true) then
            table.insert(cxxflags, {flag})
        else
            table.insert(cxxflags, flag)
        end
    end
    target:fileconfig_add(cppfile, {force = {cxxflags = cxxflags}})
end

-- populate module map
function populate_module_map(target, modules)
    local clang_version = compiler_support.get_clang_version(target)
    local support_namedmodule = semver.compare(clang_version, "16.0") >= 0
    for _, module in pairs(modules) do
        local name, provide, cppfile = compiler_support.get_provided_module(module)
        if provide then
            local bmifile = compiler_support.get_bmi_path(provide.bmi)
            add_module_to_target_mapper(target, name, cppfile, bmifile, {deps = module.requires, namedmodule = support_namedmodule})
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
    local dryrun = option.get("dry-run")

    return {
        name = job_name,
        deps = table.join(target:name() .. "_populate_module_map", deps),
        sourcefile = opt.cppfile,
        job = batchjobs:newjob(name or opt.cppfile, function(index, total, jobopt)
            local mapped_bmi
            if provide and compiler_support.memcache():get2(target:name() .. name, "reuse") then
                mapped_bmi = get_from_target_mapper(target, name).bmi
            end

            local build, dependinfo
            local dependfile = target:dependfile(bmifile or opt.objectfile)
            if provide or compiler_support.has_module_extension(opt.cppfile) then
                build, dependinfo = should_build(target, opt.cppfile, bmifile, {name = name, objectfile = opt.objectfile, requires = opt.module.requires})

                -- needed to detect rebuild of dependencies
                if provide and build then
                    mark_build(target, name)
                end
            end

            -- append requires flags
            if opt.module.requires then
                _append_requires_flags(target, opt.module, name, opt.cppfile, bmifile, opt)
            end

            -- for cpp file we need to check after appendings the flags
            if build == nil then
                build, dependinfo = should_build(target, opt.cppfile, bmifile, {name = name, objectfile = opt.objectfile, requires = opt.module.requires})
            end

            if build then
                -- compile if it's a named module
                if provide or compiler_support.has_module_extension(opt.cppfile) then
                    if not dryrun then
                        local objectdir = path.directory(opt.objectfile)
                        if not os.isdir(objectdir) then
                            os.mkdir(objectdir)
                        end
                    end

                    local fileconfig = target:fileconfig(opt.cppfile)
                    local public = fileconfig and fileconfig.public
                    local external = fileconfig and fileconfig.external
                    local from_moduleonly = external and external.moduleonly
                    local bmifile = mapped_bmi or bmifile
                    local is_mapped_bmi = mapped_bmi ~= nil
                    if external and not from_moduleonly then
                        if not mapped_bmi then
                            progress.show(jobopt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.bmi.$(mode) %s", target:name(), name or opt.cppfile)
                            _compile_bmi_step(target, bmifile, opt.cppfile, {std = (name == "std" or name == "std.compat")})
                        end
                    else
                        progress.show(jobopt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.module.$(mode) %s", target:name(), name or opt.cppfile)
                        _compile_one_step(target, bmifile, opt.cppfile, opt.objectfile, {std = (name == "std" or name == "std.compat"), is_mapped_bmi = is_mapped_bmi})
                    end
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

    local mapped_bmi
    if provide and compiler_support.memcache():get2(target:name() .. name, "reuse") then
        mapped_bmi = get_from_target_mapper(target, name).bmi
    end

    -- append requires flags
    if opt.module.requires then
        _append_requires_flags(target, opt.module, name, opt.cppfile, bmifile, opt)
    end

    -- compile if it's a named module
    if provide or compiler_support.has_module_extension(opt.cppfile) then
        batchcmds:mkdir(path.directory(opt.objectfile))

        local fileconfig = target:fileconfig(opt.cppfile)
        local public = fileconfig and fileconfig.public
        local external = fileconfig and fileconfig.external
        local bmifile = mapped_bmi or bmifile
        local is_mapped_bmi = mapped_bmi ~= nil
        if external and not from_moduleonly then
            if not mapped_bmi then
                batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.bmi.$(mode) %s", target:name(), name or opt.cppfile)
                _compile_bmi_step(target, bmifile, opt.cppfile, {std = (name == "std" or name == "std.compat"), batchcmds = batchcmds})
            end
        else
            batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.module.$(mode) %s", target:name(), name or opt.cppfile)
            _compile_one_step(target, bmifile, opt.cppfile, opt.objectfile, {std = (name == "std" or name == "std.compat"), batchcmds = batchcmds, is_mapped_bmi = is_mapped_bmi})
        end
    else
        batchcmds:rm(opt.objectfile) -- force rebuild for .cpp files
    end
    batchcmds:add_depfiles(opt.cppfile)
    return os.mtime(opt.objectfile)
end

-- build headerunit file for batchjobs
function make_headerunit_buildjobs(target, job_name, batchjobs, headerunit, bmifile, outputdir, opt)
    local already_exists = add_headerunit_to_target_mapper(target, headerunit, bmifile)
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
                    progress.show(jobopt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.headerunit.$(mode) %s", target:name(), headerunit.name)
                    _compile(target, _make_headerunitflags(target, headerunit, bmifile), headerunit.path, bmifile)
                end

                table.insert(dependinfo.files, headerunit.path)
                dependinfo.values = depvalues
                depend.save(dependinfo, dependfile)
            end)}
    end
end

-- build headerunit file for batchcmds
function make_headerunit_buildcmds(target, batchcmds, headerunit, bmifile, outputdir, opt)
    batchcmds:mkdir(outputdir)
    add_headerunit_to_target_mapper(target, headerunit, bmifile)

    if opt.build then
        local name = headerunit.unique and headerunit.name or headerunit.path
        batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.headerunit.$(mode) %s", target:name(), name)
        _batchcmds_compile(batchcmds, target, _make_headerunitflags(target, headerunit, bmifile), bmifile)
    end
    batchcmds:add_depfiles(headerunit.path)
    return os.mtime(bmifile)
end

function get_requires(target, module)
    local _requires
    local flags = _get_requiresflags(target, module)
    for _, flag in ipairs(flags) do
        _requires = _requires or {}
        table.insert(_requires, flag:split("=")[3])
    end
    return _requires
end
