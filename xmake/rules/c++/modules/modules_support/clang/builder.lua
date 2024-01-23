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

-- get flags for building a module
function _make_modulebuildflags(target, provide, bmifile, opt)

    -- get flags
    local module_outputflag = compiler_support.get_moduleoutputflag(target)

    local flags
    if module_outputflag and provide and not opt.external then -- one step compilation of named module, clang >= 16
        flags = {{"-x", "c++-module", module_outputflag .. bmifile, "-o", target:objectfile(opt.sourcefile), "-c", opt.sourcefile}}
    elseif provide then -- two step compilation of named module
        flags = {{"-x", "c++-module", "--precompile", "-o", bmifile, "-c", opt.sourcefile}}

        if not opt.external then
           table.insert(flags, {"-o", target:objectfile(opt.sourcefile), "-c", opt.sourcefile})
        end
    else -- internal module, no bmi needed
        flags = {{"-x", "c++", "-o", target:objectfile(opt.sourcefile), "-c", opt.sourcefile}}
    end

    if opt.name == "std" or opt.name == "std.compat" then
       table.join2(flags[1], {"-Wno-include-angled-in-module-purview", "-Wno-reserved-module-identifier"})
       if flags[2] then
           table.join2(flags[2], {"-Wno-include-angled-in-module-purview", "-Wno-reserved-module-identifier"})
       end
    end

    return table.unpack(flags)
end

-- get flags for building a headerunit
function _make_headerunitflags(target, headerunit, bmifile)

    local module_headerflag = compiler_support.get_moduleheaderflag(target)
    assert(module_headerflag, "compiler(clang): does not support c++ header units!")

    local local_directory = (headerunit.type == ":quote") and {"-I" .. path.directory(headerunit.path)} or {}

    local headertype = (headerunit.type == ":angle") and "system" or "user"

    local flags = table.join(local_directory, {"-xc++-header", "-Wno-everything", module_headerflag .. headertype, "-o", bmifile, "-c", headerunit.path})

    return flags
end

-- do compile
function _compile(target, flags, cppfile)

    local dryrun = option.get("dry-run")
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = cppfile, target = target})
    local msvc = target:toolchain("msvc")
    local flags = table.join(compflags or {}, flags)

    -- trace
    vprint(compinst:program(), table.unpack(flags))

    if not dryrun then
        -- do compile
        if msvc then
            assert(os.iorunv(compinst:program(), flags, {envs = msvc:runenvs()}))
        else
            assert(os.iorunv(compinst:program(), flags))
        end
    end
end

-- do compile for batchcmds
-- @note we need to use batchcmds:compilev to translate paths in compflags for generator, e.g. -Ixx
function _batchcmds_compile(batchcmds, target, flags, sourcefile)

    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
    batchcmds:compilev(table.join(compflags or {}, flags), {compiler = compinst, sourcekind = "cxx"})
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

    local requiresflags = compiler_support.memcache():get2(cachekey, "requiresflags")
                       or compiler_support.localcache():get2(cachekey, "requiresflags")

    if not requiresflags or (opt and opt.regenerate) then
        requiresflags = {}
        for required, _ in pairs(module.requires) do
            local dep_module = get_from_target_mapper(target, required)

            assert(dep_module, "module dependency %s required for %s not found", required, name)

            local bmifile = dep_module.bmi
            local mapflag = (dep_module.opt and dep_module.opt.namedmodule) and format("%s%s=%s", modulefileflag, required, bmifile) or modulefileflag .. bmifile
            table.insert(requiresflags, mapflag)

            -- append deps
            if dep_module.opt and dep_module.opt.deps then
                local deps = _get_requiresflags(target, {name = dep_module.name or dep_module.sourcefile, bmi = bmifile, requires = dep_module.opt.deps})
                table.join2(requiresflags, deps)
            end
        end
        compiler_support.memcache():set2(cachekey, "requiresflags", table.unique(requiresflags))
        compiler_support.localcache():set2(cachekey, "requiresflags", table.unique(requiresflags))
    end

    return requiresflags
end

function _append_requires_flags(target, module, name, cppfile, bmifile, opt)

    local cxxflags = {}
    local requiresflags = _get_requiresflags(target, {name = (name or cppfile), bmi = bmifile, requires = module.requires}, {regenerate = opt.build})

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
function make_module_build_job(target, batchjobs, job_name, deps, opt)

    local name, provide, _ = compiler_support.get_provided_module(opt.module)
    local bmifile = provide and compiler_support.get_bmi_path(provide.bmi)
    local dryrun = option.get("dry-run")
    local populate_job_name = get_modulemap_populate_jobname(target)

    return {
        name = job_name,
        deps = table.join({populate_job_name}, deps),
        sourcefile = cppfile,
        job = batchjobs:newjob(name or opt.cppfile, function(index, total)

            local compinst = compiler.load("cxx", {target = target})
            local compflags = compinst:compflags({sourcefile = opt.cppfile, target = target})

            -- append requires flags
            if opt.module.requires then
                _append_requires_flags(target, opt.module, name, opt.cppfile, bmifile, opt)
            end

            local dependfile = target:dependfile(bmifile or opt.objectfile)
            local dependinfo = depend.load(dependfile) or {}
            dependinfo.files = {}
            local depvalues = {compinst:program(), compflags}

            -- compile if it's a named module
            if opt.build and (provide or compiler_support.has_module_extension(opt.cppfile)) then
                progress.show((index * 100) / total, "${color.build.target}<%s> ${clear}${clear}${color.build.object}compiling.module.$(mode) %s", target:name(), name or opt.cppfile)

                if not dryrun then
                    local objectdir = path.directory(opt.objectfile)
                    if not os.isdir(objectdir) then
                        os.mkdir(objectdir)
                    end
                end

                local fileconfig = target:fileconfig(opt.cppfile)
                local external = fileconfig and fileconfig.external

                local first_step, second_step = _make_modulebuildflags(target, provide, bmifile, {sourcefile = opt.cppfile, external = external, name = name})

                _compile(target, first_step, opt.cppfile)

                if second_step then
                    _compile(target, second_step, opt.cppfile)
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
    local bmifile = provide and compiler_support.get_bmi_path(provide.bmi)

    -- append requires flags
    if opt.module.requires then
        _append_requires_flags(target, opt.module, name, opt.cppfile, bmifile, opt)
    end

    -- compile if it's a named module
    if opt.build and (provide or compiler_support.has_module_extension(opt.cppfile)) then
        batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}compiling.module.$(mode) %s", target:name(), name or opt.cppfile)
        batchcmds:mkdir(path.directory(opt.objectfile))

        local fileconfig = target:fileconfig(opt.cppfile)
        local external = fileconfig and fileconfig.external

        local first_step, second_step = _make_modulebuildflags(target, provide, bmifile, {batchcmds = true, sourcefile = opt.cppfile, external = external, name = name})
        _batchcmds_compile(batchcmds, target, first_step, opt.cppfile)

        if second_step then
            _batchcmds_compile(batchcmds, target, second_step, opt.cppfile)
        end
    end
    batchcmds:add_depfiles(opt.cppfile)

    return os.mtime(opt.objectfile)
end

-- build headerunit file for batchjobs
function make_headerunit_build_job(target, job_name, batchjobs, headerunit, bmifile, outputdir, opt)

    add_headerunit_to_target_mapper(target, headerunit, bmifile)
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
                progress.show((index * 100) / total, "${color.build.target}<%s> ${clear}${color.build.object}compiling.headerunit.$(mode) %s", target:name(), headerunit.name)
                _compile(target, _make_headerunitflags(target, headerunit, bmifile), headerunit.path)
            end

            table.insert(dependinfo.files, headerunit.path)
            dependinfo.values = depvalues
            depend.save(dependinfo, dependfile)
        end)}
end

-- build headerunit file for batchcmds
function make_headerunit_build_cmds(target, batchcmds, headerunit, bmifile, outputdir, opt)

    batchcmds:mkdir(outputdir)

    add_headerunit_to_target_mapper(target, headerunit, bmifile)

    if opt.build then
        local name = headerunit.unique and headerunit.name or headerunit.path
        batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.headerunit.$(mode) %s", target:name(), name)
        _batchcmds_compile(batchcmds, target, _make_headerunitflags(target, headerunit, bmifile))
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

