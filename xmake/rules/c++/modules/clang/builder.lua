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
import("support")
import(".mapper")
import(".builder", {inherit = true})

function _make_modulebuildflags(target, module, opt)

    local flags = {}
    if opt and opt.bmi then
        local module_outputflag = support.get_moduleoutputflag(target)

        flags = {"-x", "c++-module"}
        if not opt.objectfile then
            table.insert(flags, "--precompile")
        end
        local std = (module.name == "std" or module.name == "std.compat")
        if std then
            table.join2(flags, {"-Wno-include-angled-in-module-purview", "-Wno-reserved-module-identifier", "-Wno-deprecated-declarations"})
        end
        table.insert(flags, module_outputflag .. module.bmifile)
    end

    return flags
end

function _compile_one_step(target, module, opt)

    -- get flags
    if module_outputflag then
        local flags = _make_modulebuildflags(target, module, {bmi = true, objectfile = true})
        if opt and opt.batchcmds then
            _batchcmds_compile(opt.batchcmds, target, flags, module.sourcefile, module.objectfile)
        else
            _compile(target, flags, module.sourcefile, module.objectfile)
        end
    else
        _compile_bmi_step(target, module, opt)
        _compile_objectfile_step(target, module, opt)
    end
end

function _compile_bmi_step(target, module, opt)

    local flags = _make_modulebuildflags(target, module, {bmi = true, objectfile = false})
    if opt and opt.batchcmds then
        _batchcmds_compile(opt.batchcmds, target, flags, module.sourcefile, module.bmifile, opt)
    else
        _compile(target, flags, module.sourcefile, module.bmifile)
    end
end

function _compile_objectfile_step(target, module, opt)
    local flags = _make_modulebuildflags(target, module, {bmi = false, objectfile = false})
    if opt and opt.batchcmds then
        _batchcmds_compile(opt.batchcmds, target, flags, module.sourcefile, module.objectfile, {bmifile = module.bmifile})
    else
        _compile(target, flags, module.sourcefile, module.objectfile, {bmifile = module.bmifile})
    end
end

-- get flags for building a headerunit
function _make_headerunitflags(target, headerunit)

    local module_headerflag = support.get_moduleheaderflag(target)
    assert(module_headerflag, "compiler(clang): does not support c++ header units!")

    local local_directory = (headerunit.type == ":quote") and {"-I" .. path.directory(headerunit.path)} or {}
    local headertype = (headerunit.method == "include-quote") and "system" or "user"
    local flags = table.join(local_directory, {"-xc++-header", "-Wno-everything", module_headerflag .. headertype})
    return flags
end

-- do compile
function _compile(target, flags, sourcefile, outputfile, opt)

    opt = opt or {}
    local dryrun = option.get("dry-run")
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"})
    flags = table.join(flags or {}, compflags or {})

    local bmifile = opt and opt.bmifile

    -- trace
    if option.get("verbose") then
        print(compinst:compcmd(bmifile or sourcefile, outputfile, {target = target, compflags = flags, sourcekind = "cxx", rawargs = true}))
    end

    -- do compile
    if not dryrun then
        assert(compinst:compile(bmifile or sourcefile, outputfile, {target = target, compflags = flags}))
    end
end

-- do compile for batchcmds
-- @note we need to use batchcmds:compilev to translate paths in compflags for generator, e.g. -Ixx
function _batchcmds_compile(batchcmds, target, flags, sourcefile, outputfile, opt)
    opt = opt or {}
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"})
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
function _get_requiresflags(target, module)

    local modulefileflag = support.get_modulefileflag(target)
    local name = module.name or module.sourcefile
    local cachekey = target:fullname() .. name

    local requires, requires_changed = is_dependencies_changed(target, module)
    local requiresflags = support.memcache():get2(cachekey, "requiresflags")
    if not requiresflags or requires_changed then
        requiresflags = {}
        for required, dep in pairs(module.deps) do
            if dep.headerunit then
                required = required .. dep.key
            end
            local dep_module = mapper.get(target, required)
            assert(dep_module, "module dependency %s required for %s not found", required, name)

            local mapflag = dep_module.headerunit and modulefileflag .. dep_module.bmifile or format("%s%s=%s", modulefileflag, required, dep_module.bmifile)
            table.insert(requiresflags, mapflag)

            -- append deps
            if dep_module.deps then
                local deps = _get_requiresflags(target, dep_module)
                table.join2(requiresflags, deps)
            end
        end
        requiresflags = table.unique(requiresflags)
        table.sort(requiresflags)
        support.memcache():set2(cachekey, "requiresflags", requiresflags)
        support.memcache():set2(cachekey, "oldrequires", requires)
    end
    return requiresflags
end

function _append_requires_flags(target, module)

    local cxxflags = {}
    local requiresflags = _get_requiresflags(target, module)
    for _, flag in ipairs(requiresflags) do
        -- we need to wrap flag to support flag with space
        if type(flag) == "string" and flag:find(" ", 1, true) then
            table.insert(cxxflags, {flag})
        else
            table.insert(cxxflags, flag)
        end
    end
    target:fileconfig_add(module.sourcefile, {force = {cxxflags = cxxflags}})
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

    -- append requires flags
    -- if module.deps then
    --     _append_requires_flags(target, module)
    -- end

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

    local build = should_build(target, module)
    local bmi = opt and opt.bmi
    local objectfile = opt and opt.objectfile

    if build then
        if not dryrun then
            local objectdir = path.directory(module.objectfile)
            batchcmds:mkdir(objectdir)
            if module.bmifile then
                local bmidir = path.directory(module.bmifile)
                batchcmds:mkdir(bmidir)
            end
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
        batchcmds:add_depfiles(module.sourcefile)
    end
    return os.mtime(module.objectfile)
end

-- build headerunit file for batchjobs / jobgraph
function make_headerunit_job(target, headerunit, opt)

    local build = should_build(target, headerunit)
    if build then
        local name = headerunit.unique and path.filename(headerunit.name) or headerunit.name
        progress.show(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.headerunit.$(mode) %s", target:fullname(), name)
        _compile(target, _make_headerunitflags(target, headerunit), headerunit.sourcefile, headerunit.bmifile)
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
        batchcmds:show_progress(opt.progress, "${color.build.target}<%s> ${clear}${color.build.object}compiling.headerunit.$(mode) %s", target:fullname(), name)
        _batchcmds_compile(batchcmds, target, table.join(_make_headerunitflags(target, headerunit)), headerunit.sourcefile, headerunit.bmifile)
        batchcmds:add_depfiles(headerunit.sourcefile)
    end
    batchcmds:add_depvalues(depvalues)
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
