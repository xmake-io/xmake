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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki, Arthapz
-- @file        clang/builder.lua
--

-- imports
import("core.base.json")
import("core.base.bytes")
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

function _get_bmifile(target, module)
    local has_reduced_bmi = support.get_modulesreducedbmiflag(target)
    local has_two_phases = target:policy("build.c++.modules.two_phases")
    -- disabled with two phases currently, LLVM currently have a bug which prevent to emit reduced bmi when using two phase compilation
    -- will be enabled after the fix
    local add_reduced_flag = not has_two_phases and has_reduced_bmi
    local bmifile = module.bmifile

    if has_two_phases and add_reduced_flag then
        bmifile = path.join(path.directory(module.bmifile), "reduced." .. path.filename(module.bmifile))
    end

    return bmifile, add_reduced_flag
end

function _update_bmihash(target, module)
    local localcache = support.localcache()

    local bmifile = _get_bmifile(target, module)
    local bmihash = hash.xxhash128(bytes(io.readfile(bmifile)))
    local old_bmihash = localcache:get2(bmifile, "hash")

    if not old_bmihash or bmihash ~= old_bmihash then
        localcache:set2(bmifile, "hash", bmihash)
        support.memcache():set2(bmifile, "updated", true)
    end
end

function _make_modulebuildflags(target, module, opt)
    assert(not module.headerunit)

    local modules_reduced_bmi_flag = support.get_modulesreducedbmiflag(target)
    local has_two_phases = target:policy("build.c++.modules.two_phases")
    local flags
    if opt.bmi then
        local module_outputflag = support.get_moduleoutputflag(target)

        flags = {"-x", "c++-module"}

        if not opt.objectfile then
            table.insert(flags, "--precompile")
            if target:has_tool("cxx", "clang_cl") then
                table.join2(flags, "/clang:-o", "/clang:" .. module.bmifile)
            end
        end
        local std = (module.name == "std" or module.name == "std.compat")
        if std then
            table.join2(flags, {"-Wno-include-angled-in-module-purview", "-Wno-reserved-module-identifier", "-Wno-deprecated-declarations"})
        end

        local bmifile, add_reduced_flag = _get_bmifile(target, module)
        if add_reduced_flag then
            table.insert(flags, modules_reduced_bmi_flag)
        end

        if not has_two_phases or add_reduced_flag  then
            table.insert(flags, module_outputflag .. bmifile)
        end
    else
        flags = {}
        if not has_two_phases or not module.bmifile then
            flags = {"-x", "c++"}
        end
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


function _get_mapper_str(target, module, opt)
    local mapper_str
    if target:policy("build.c++.modules.hide_dependencies") and option.get("diagnosis") then
        if not opt.headerunit then
            local requires_flagsfile = target:autogenfile(module.sourcefile .. ".requiresflags.txt")
            if os.isfile(requires_flagsfile) then
                if module.name then
                    mapper_str = format("\n${dim color.warning}mapper file for %s (%s) --------\n%s\n--------", module.name, module.sourcefile, io.readfile(requires_flagsfile):trim())
                else
                    mapper_str = format("\n${dim color.warning}mapper file for %s --------\n%s\n--------", module.sourcefile, io.readfile(requires_flagsfile):trim())
                end
            end
        end
    end
    return mapper_str
end

-- do compile
function _compile(target, flags, module, opt)

    opt = opt or {}
    local sourcefile = module.sourcefile
    if not opt.bmi and opt.objectfile and module.bmifile then
        sourcefile = module.bmifile
    end
    local outputfile = ((opt.bmi and not opt.objectfile) or opt.headerunit) and module.bmifile or module.objectfile
    local dryrun = option.get("dry-run")
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = module.sourcefile, target = target, sourcekind = "cxx"})
    flags = table.join(compflags or {}, flags or {})
    -- trace
    local cmd
    if option.get("verbose") then
        cmd = "\n" .. compinst:compcmd(sourcefile, outputfile, {target = target, compflags = flags, sourcekind = "cxx", rawargs = true})
    end
    show_progress(target, module, table.join(opt, {cmd = cmd, suffix = _get_mapper_str(target, module, opt)}))

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
    local compflags = compinst:compflags({sourcefile = module.sourcefile, target = target, sourcekind = "cxx"})
    flags = table.join("-c", compflags or {}, flags or {}, {"-o", outputfile, sourcefile})

    -- trace
    local cmd
    if option.get("verbose") then
        cmd = "\n" .. compinst:compcmd(sourcefile, outputfile, {target = target, compflags = flags, sourcekind = "cxx", rawargs = true})
    end
    show_progress(target, module, table.join(opt, {cmd = cmd, batchcmds = batchcmds, suffix = _get_mapper_str(target, module, opt)}))

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

            local dep_bmifile, _ = dep.headerunit and dep_module.bmifile or _get_bmifile(target, dep_module)
            local mapflag = dep_module.headerunit and modulefileflag .. dep_bmifile or format("%s%s=%s", modulefileflag, required, dep_bmifile)
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
    local has_two_phases = target:policy("build.c++.modules.two_phases")
    local hide_dependencies = target:policy("build.c++.modules.hide_dependencies")
    if #requiresflags> 0 then
        for _, flag in ipairs(requiresflags) do
            -- we need to wrap flag to support flag with space
            if type(flag) == "string" and flag:find(" ", 1, true) and not hide_dependencies then
                table.insert(cxxflags, {flag})
            else
                if hide_dependencies then
                    table.insert(cxxflags, '"' .. path.unix(flag) .. '"')
                else
                    table.insert(cxxflags, flag)
                end
            end
        end
        if hide_dependencies then
            local requires_flagsfile = target:autogenfile(module.sourcefile .. ".requiresflags.txt")
            io.writefile(requires_flagsfile, path.unix(table.concat(cxxflags, "\n")))
            target:fileconfig_add(module.sourcefile, {force = {cxxflags = {{"@" .. requires_flagsfile}}}})
        else
            target:fileconfig_add(module.sourcefile, {force = {cxxflags = cxxflags}})
        end
    end
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
    local enable_hash_comparison = target:policy("build.c++.modules.non_cascading_changes")

    local build, because_of_dependencies = should_build(target, module)
    local bmi = opt and opt.bmi
    local objectfile = opt and opt.objectfile

    if build and enable_hash_comparison and because_of_dependencies then
        build = false
        for dep_name, dep_module in table.orderpairs(module.deps) do
            local mapped_dep = mapper.get(target, dep_module.headerunit and dep_name .. dep_module.key or dep_name)
            if support.memcache():get2(_get_bmifile(target, dep_module), "updated") then
                build = true
                break
            end
        end
    end

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

        if enable_hash_comparison and bmi then
            _update_bmihash(target, module)
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
