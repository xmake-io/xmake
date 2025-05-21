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
    assert(not module.headerunit)
    local flags
    if opt.bmi then
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
    else
        flags = {"-x", "c++"}
        local std = (module.name == "std" or module.name == "std.compat")
        if std then
            table.join2(flags, {"-Wno-include-angled-in-module-purview", "-Wno-reserved-module-identifier", "-Wno-deprecated-declarations"})
        end
    end
    return flags
end

function _compile_one_step(target, module, opt)
    -- get flags
    local module_outputflag = support.get_moduleoutputflag(target)
    if module_outputflag then
        local flags = _make_modulebuildflags(target, module, opt)
        if opt and opt.batchcmds then
            _batchcmds_compile(opt.batchcmds, target, flags, module, opt)
        else
            _compile(target, flags, module, opt)
        end
    else
        _compile_bmi_step(target, module, opt)
        _compile_objectfile_step(target, module, opt)
    end
end

function _compile_bmi_step(target, module, opt)
    local flags = _make_modulebuildflags(target, module, opt)
    if opt and opt.batchcmds then
        _batchcmds_compile(opt.batchcmds, target, flags, module, opt)
    else
        _compile(target, flags, module, opt)
    end
end

function _compile_objectfile_step(target, module, opt)
    local flags = _make_modulebuildflags(target, module, opt)
    if opt and opt.batchcmds then
        _batchcmds_compile(opt.batchcmds, target, flags, module, opt)
    else
        _compile(target, flags, module, opt)
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
function _compile(target, flags, module, opt)

    opt = opt or {}
    local sourcefile = module.sourcefile
    local outputfile = ((opt.bmi and not opt.objectfile) or opt.headerunit) and module.bmifile or module.objectfile
    local dryrun = option.get("dry-run")
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"})
    flags = table.join(compflags or {}, flags or {})
    -- trace
    local cmd
    if option.get("verbose") then
        cmd = "\n" .. compinst:compcmd(sourcefile, outputfile, {target = target, compflags = flags, sourcekind = "cxx", rawargs = true})
    end
    show_progress(target, module, table.join(opt, {cmd = cmd}))

    -- do compile
    if not dryrun then
        assert(compinst:compile(sourcefile, outputfile, {target = target, compflags = flags}))
    end
end

-- do compile for batchcmds
-- @note we need to use batchcmds:compilev to translate paths in compflags for generator, e.g. -Ixx
function _batchcmds_compile(batchcmds, target, flags, module, opt)
    opt = opt or {}
    local sourcefile = module.sourcefile
    local outputfile = (opt.bmi and not opt.objectfile) and module.bmifile or module.objectfile
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"})
    flags = table.join("-c", compflags or {}, flags or {}, {"-o", outputfile, sourcefile})

    -- trace
    local cmd
    if option.get("verbose") then
        cmd = "\n" .. compinst:compcmd(sourcefile, outputfile, {target = target, compflags = flags, sourcekind = "cxx", rawargs = true})
    end
    show_progress(target, module, table.join(opt, {cmd = cmd, batchcmds = batchcmds}))

    -- do compile
    batchcmds:compilev(flags, {compiler = compinst, sourcekind = "cxx", verbose = false})
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
        for required, dep in table.orderpairs(module.deps) do
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
            _compile_one_step(target, module, opt)
        elseif bmi then
            _compile_bmi_step(target, module, opt)
        else
            if support.has_module_extension(module.sourcefile) or module.name then
                _compile_objectfile_step(target, module, opt)
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
            _compile_one_step(target, module, table.join(opt, {batchcmds = batchcmds}))
        elseif bmi then
            _compile_bmi_step(target, module, table.join(opt, {batchcmds = batchcmds}))
        else
            if support.has_module_extension(module.sourcefile) or module.name then
                _compile_objectfile_step(target, module, table.join(opt, {batchcmds = batchcmds}))
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
        _compile(target, _make_headerunitflags(target, headerunit), headerunit, table.join(opt, {headerunit = true}))
    end
end

-- build headerunit file for batchcmds
function make_headerunit_buildcmds(target, batchcmds, headerunit, opt)
    local compinst = compiler.load("cxx", {target = target})
    local compflags = compinst:compflags({sourcefile = headerunit.sourcefile, target = target, sourcekind = "cxx"})
    local depvalues = {compinst:program(), compflags}

    local build = should_build(target, headerunit)
    if build then
        _batchcmds_compile(batchcmds, target, table.join(_make_headerunitflags(target, headerunit)), headerunit, table.join(opt, {headerunit = true}))
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
