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
-- @file        clang.lua
--

-- imports
import("core.base.option")
import("core.tool.compiler")
import("core.project.project")
import("core.project.depend")
import("core.project.config")
import("utils.progress")
import("private.action.build.object", {alias = "objectbuilder"})
import("common")
import("stl_headers")

-- add a module or an header unit into the mapper
--
-- e.g
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/foo.pcm
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/iostream.pcm
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/bar.hpp.pcm
--
function _add_module_to_mapper(target, name, bmifile, deps)
    local modulemap = _get_modulemap_from_mapper(target)
    if modulemap[name] then
        return
    end

    local modulefileflag = get_modulefileflag(target)
    local mapflag = format("%s%s", modulefileflag, bmifile)
    modulemap[name] = {flag = mapflag, deps = deps}
    common.localcache():set2(_mapper_cachekey(target), "modulemap", modulemap)
end

function _mapper_cachekey(target)
    local mode = config.mode()
    return target:name() .. "_modulemap_" .. (mode or "")
end

-- flush modulemap to mapper file cache
function _flush_mapper(target)
    -- not using set2/get2 to flush only current target mapper
    common.localcache():save(_mapper_cachekey(target))
end

-- get modulemap from mapper
function _get_modulemap_from_mapper(target)
    return common.localcache():get2(_mapper_cachekey(target), "modulemap") or {}
end

-- load module support for the current target
function load(target)
    local modulesflag = get_modulesflag(target)
    local builtinmodulemapflag = get_builtinmodulemapflag(target)
    local implicitmodulesflag = get_implicitmodulesflag(target)

    -- add module flags
    target:add("cxxflags", modulesflag)
    target:add("cxxflags", builtinmodulemapflag, {force = true})
    target:add("cxxflags", implicitmodulesflag, {force = true})

    -- TODO fix default visibility for functions and variables [-fvisibility] differs in PCH file vs. current file
    -- module.pcm cannot be loaded due to a configuration mismatch with the current compilation.
    --
    -- it will happen in binary target depend ont shared target with modules, and enable release mode at same time.
    target:set("symbols", "none")

    -- if use libc++, we need install libc++ and libc++abi
    --
    -- on ubuntu:
    -- sudo apt install libc++-dev libc++abi-15-dev
    --
    target:data_set("cxx.modules.use_libc++", table.contains(target:get("cxxflags"), "-stdlib=libc++"))
    if target:data("cxx.modules.use_libc++") then
        target:add("syslinks", "c++")
    end
end

-- get includedirs for stl headers
--
-- $ echo '#include <vector>' | clang -x c++ -E - | grep '/vector"'
-- # 1 "/usr/include/c++/11/vector" 1 3
-- # 58 "/usr/include/c++/11/vector" 3
-- # 59 "/usr/include/c++/11/vector" 3
--
function _get_toolchain_includedirs_for_stlheaders(includedirs, clang)
    local tmpfile = os.tmpfile() .. ".cc"
    io.writefile(tmpfile, "#include <vector>")
    local argv = {"-E", "-x", "c++", tmpfile}
    if target:data("cxx.modules.use_libc++") then
        table.insert(argv, 1, "-stdlib=libc++")
    end
    local result = try {function () return os.iorunv(clang, {"-E", "-x", "c++", tmpfile}) end}
    if result then
        for _, line in ipairs(result:split("\n", {plain = true})) do
            line = line:trim()
            if line:startswith("#") and line:find("/vector\"", 1, true) then
                local includedir = line:match("\"(.+)/vector\"")
                if includedir and os.isdir(includedir) then
                    table.insert(includedirs, path.normalize(includedir))
                    break
                end
            end
        end
    end
    os.tryrm(tmpfile)
end

-- build module file
function _build_modulefile(target, sourcefile, opt)
    local objectfile = opt.objectfile
    local dependfile = opt.dependfile
    local compinst = compiler.load("cxx", {target = target})
    local compflags = compinst:compflags({target = target})
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

    -- need build this object?
    local dryrun = option.get("dry-run")
    local depvalues = {compinst:program(), compflags}
    local lastmtime = os.isfile(objectfile) and os.mtime(dependfile) or 0
    if not dryrun and not depend.is_changed(dependinfo, {lastmtime = lastmtime, values = depvalues}) then
        return
    end

    local bmifile = opt.bmifile
    local common_args = opt.common_args
    local requiresflags = opt.requiresflags
    local bmiflags = table.join("-x", "c++-module", "--precompile", compflags, common_args, requiresflags or {})
    local objflags = table.join(compflags, common_args, requiresflags or {})

    -- trace
    progress.show(opt.progress, "${color.build.object}generating.cxx.module.bmi %s", opt.name)
    vprint(compinst:compcmd(sourcefile, bmifile, {compflags = bmiflags, rawargs = true}))
    vprint(compinst:compcmd(bmifile, objectfile, {compflags = objflags, rawargs = true}))

    if not dryrun then

        -- do compile
        dependinfo.files = {}
        assert(compinst:compile(sourcefile, bmifile, {dependinfo = dependinfo, compflags = bmiflags}))
        assert(compinst:compile(bmifile, objectfile, {compflags = objflags}))

        -- update files and values to the dependent file
        dependinfo.values = depvalues
        table.join2(dependinfo.files, sourcefile)
        depend.save(dependinfo, dependfile)
    end
end

-- provide toolchain include directories for stl headerunit when p1689 is not supported
function toolchain_includedirs(target)
    local includedirs = _g.includedirs
    if includedirs == nil then
        includedirs = {}
        local clang, toolname = target:tool("cc")
        assert(toolname == "clang")
        _get_toolchain_includedirs_for_stlheaders(includedirs, clang)
        local _, result = try {function () return os.iorunv(clang, {"-E", "-Wp,-v", "-xc", os.nuldev()}) end}
        if result then
            for _, line in ipairs(result:split("\n", {plain = true})) do
                line = line:trim()
                if os.isdir(line) then
                    table.insert(includedirs, path.normalize(line))
                elseif line:startswith("End") then
                    break
                end
            end
        end
        _g.includedirs = includedirs
    end
    return includedirs
end

-- generate dependency files
function generate_dependencies(target, sourcebatch, opt)
    local changed = false
    local cachedir = common.modules_cachedir(target)
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function()
            if opt.progress then
                progress.show(opt.progress, "${color.build.object}generating.cxx.module.deps %s", sourcefile)
            end

            local outputdir = path.translate(path.join(cachedir, path.directory(path.relative(sourcefile, projectdir))))
            if not os.isdir(outputdir) then
                os.mkdir(outputdir)
            end

            -- no support of p1689 atm
            local jsonfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".json"))
            common.fallback_generate_dependencies(target, jsonfile, sourcefile)
            changed = true

            local dependinfo = io.readfile(jsonfile)
            return {moduleinfo = dependinfo}
        end, {dependfile = dependfile, files = {sourcefile}})
    end
    return changed
end

-- generate target stl header units for batchjobs
function generate_stl_headerunits_for_batchjobs(target, batchjobs, headerunits, opt)
    local compinst = target:compiler("cxx")
    local stlcachedir = common.stlmodules_cachedir(target)
    local modulecachepathflag = get_modulecachepathflag(target)
    assert(has_headerunitsupport(target), "compiler(clang): does not support c++ header units!")

    -- flush job
    local flushjob = batchjobs:addjob(target:name() .. "_stl_headerunits_flush_mapper", function(index, total)
        _flush_mapper(target)
    end, {rootjob = opt.rootjob})

    -- build headerunits
    for i, headerunit in ipairs(headerunits) do
        local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_extension())
        if not os.isfile(bmifile) then
            batchjobs:addjob(headerunit.name, function (index, total)
                depend.on_changed(function()
                    -- don't build same header unit at the same time
                    if not common.memcache():get2(headerunit.name, "building") then
                        common.memcache():set2(headerunit.name, "building", true)
                        progress.show((index * 100) / total, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
                        local args = {modulecachepathflag .. stlcachedir, "-c", "-o", bmifile, "-x", "c++-system-header", headerunit.name}
                        os.vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))
                    end

                end, {dependfile = target:dependfile(bmifile), files = {headerunit.path}})
                -- libc++ have a builtin module mapper
                if not target:data_set("cxx.modules.use_libc++") then
                    _add_module_to_mapper(target, headerunit.name, bmifile)
                end
            end, {rootjob = flushjob})
        end
    end
end

-- generate target stl header units for batchcmds
function generate_stl_headerunits_for_batchcmds(target, batchcmds, headerunits, opt)
    local compinst = target:compiler("cxx")
    local stlcachedir = common.stlmodules_cachedir(target)
    local modulecachepathflag = get_modulecachepathflag(target)
    assert(has_headerunitsupport(target), "compiler(clang): does not support c++ header units!")

    -- build headerunits
    local projectdir = os.projectdir()
    local depmtime = 0
    for i, headerunit in ipairs(headerunits) do
        local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_extension())
        -- don't build same header unit at the same time
        if not common.memcache():get2(headerunit.name, "building") then
            common.memcache():set2(headerunit.name, "building", true)
            local args = {
                path(stlcachedir, function (p) return modulecachepathflag .. p end),
                "-c", "-o", path(bmifile), "-x", "c++-system-header", headerunit.name}
            batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))
        end
        -- libc++ have a builtin module mapper
        if not target:data_set("cxx.modules.use_libc++") then
            _add_module_to_mapper(target, headerunit.name, bmifile)
        end
        depmtime = math.max(depmtime, os.mtime(bmifile))
    end
    batchcmds:set_depmtime(depmtime)
    _flush_mapper(target)
end

-- generate target user header units for batchjobs
function generate_user_headerunits_for_batchjobs(target, batchjobs, headerunits, opt)
    local compinst = target:compiler("cxx")
    assert(has_headerunitsupport(target), "compiler(clang): does not support c++ header units!")

    -- get cachedirs
    local cachedir = common.modules_cachedir(target)
    local modulecachepathflag = get_modulecachepathflag(target)

    -- flush job
    local flushjob = batchjobs:addjob(target:name() .. "_user_headerunits_flush_mapper", function(index, total)
        _flush_mapper(target)
    end, {rootjob = opt.rootjob})

    -- build headerunits
    local projectdir = os.projectdir()
    for _, headerunit in ipairs(headerunits) do
        local file = path.relative(headerunit.path, target:scriptdir())
        local objectfile = target:objectfile(file)

        local outputdir
        if headerunit.type == ":quote" then
            outputdir = path.join(cachedir, path.directory(path.relative(headerunit.path, projectdir)))
        else
            outputdir = path.join(cachedir, path.directory(headerunit.path))
        end
        local bmifilename = path.basename(objectfile) .. get_bmi_extension()
        local bmifile = (outputdir and path.join(outputdir, bmifilename) or bmifilename)
        batchjobs:addjob(headerunit.name, function (index, total)
            depend.on_changed(function()
                progress.show((index * 100) / total, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
                local objectdir = path.directory(objectfile)
                if not os.isdir(objectdir) then
                    os.mkdir(objectdir)
                end
                if not os.isdir(outputdir) then
                    os.mkdir(outputdir)
                end

                -- generate headerunit
                local args = { modulecachepathflag .. cachedir, "-c", "-o", bmifile}
                if headerunit.type == ":quote" then
                    table.join2(args, {"-I", path.directory(headerunit.path), "-x", "c++-user-header", headerunit.path})
                elseif headerunit.type == ":angle" then
                    table.join2(args, {"-x", "c++-system-header", headerunit.name})
                end
                os.vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))

            end, {dependfile = target:dependfile(bmifile), files = {headerunit.path}})
            _add_module_to_mapper(target, headerunit.name, bmifile)
        end, {rootjob = flushjob})
    end
end

-- generate target user header units for batchcmds
function generate_user_headerunits_for_batchcmds(target, batchcmds, headerunits, opt)
    local compinst = target:compiler("cxx")
    assert(has_headerunitsupport(target), "compiler(clang): does not support c++ header units!")

    -- get cachedirs
    local cachedir = common.modules_cachedir(target)
    local modulecachepathflag = get_modulecachepathflag(target)

    -- build headerunits
    local projectdir = os.projectdir()
    local depmtime = 0
    for _, headerunit in ipairs(headerunits) do
        local file = path.relative(headerunit.path, target:scriptdir())
        local objectfile = target:objectfile(file)

        local outputdir
        if headerunit.type == ":quote" then
            outputdir = path.join(cachedir, path.directory(path.relative(headerunit.path, projectdir)))
        else
            outputdir = path.join(cachedir, path.directory(headerunit.path))
        end
        batchcmds:mkdir(outputdir)

        local bmifilename = path.basename(objectfile) .. get_bmi_extension()
        local bmifile = (outputdir and path.join(outputdir, bmifilename) or bmifilename)
        batchcmds:mkdir(path.directory(objectfile))

        local args = {path(cachedir, function (p) return modulecachepathflag .. p end), "-c", "-o", path(bmifile)}
        if headerunit.type == ":quote" then
            table.join2(args, {"-I", path(headerunit.path):directory(), "-x", "c++-user-header", path(headerunit.path)})
        elseif headerunit.type == ":angle" then
            table.join2(args, {"-x", "c++-system-header", headerunit.name})
        end

        batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
        batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))
        batchcmds:add_depfiles(headerunit.path)

        _add_module_to_mapper(target, headerunit.name, bmifile)

        depmtime = math.max(depmtime, os.mtime(bmifile))
    end
    batchcmds:set_depmtime(depmtime)
    _flush_mapper(target)
end

-- build module files for batchjobs
function build_modules_for_batchjobs(target, batchjobs, objectfiles, modules, opt)
    local compinst = target:compiler("cxx")
    local cachedir = common.modules_cachedir(target)
    local modulecachepathflag = get_modulecachepathflag(target)
    local modulefileflag = get_modulefileflag(target)

    -- flush job
    local flushjob = batchjobs:addjob(target:name() .. "_stl_flush_mapper", function(index, total)
        _flush_mapper(target)
    end, {rootjob = opt.rootjob})

    -- build modules
    local common_args = {modulecachepathflag .. cachedir}
    local modulesjobs = {}
    for _, objectfile in ipairs(objectfiles) do
        local module = modules[objectfile]
        if module then
            if module.provides then
                -- assume there that provides is only one, until we encounter the case
                local length = 0
                local name, provide
                for k, v in pairs(module.provides) do
                    length = length + 1
                    name = k
                    provide = v
                    if length > 1 then
                        raise("multiple provides are not supported now!")
                    end
                end

                local bmifile = provide.bmi
                local moduleinfo = table.copy(provide)
                moduleinfo.job = batchjobs:newjob(provide.sourcefile, function (index, total)
                    -- append module mapper flags first
                    -- @note we add it at the end to ensure that the full modulemap are already stored in the mapper
                    local requiresflags
                    if module.requires then
                        requiresflags = get_requiresflags(target, module.requires)
                    end

                    _build_modulefile(target, provide.sourcefile, {
                        objectfile = objectfile,
                        dependfile = target:dependfile(bmifile),
                        bmifile = bmifile,
                        name = name,
                        common_args = common_args,
                        requiresflags = requiresflags,
                        progress = (index * 100) / total})

                    _add_module_to_mapper(target, name, bmifile, requiresflags)
                end)
                if module.requires then
                    moduleinfo.deps = table.keys(module.requires)
                end
                moduleinfo.name = name
                modulesjobs[name] = moduleinfo
                target:add("objectfiles", objectfile)
            else
                if module.requires then
                    modulesjobs[module.cppfile] = {
                        name = module.cppfile,
                        deps = table.keys(module.requires),
                        sourcefile = module.cppfile,
                        job = batchjobs:newjob(module.cppfile, function(index, total)
                            -- append module mapper flags
                            -- @note we add it at the end to ensure that the full modulemap are already stored in the mapper
                            local requiresflags = get_requiresflags(target, module.requires)
                            if requiresflags then
                                target:fileconfig_add(module.cppfile, {force = {cxxflags = requiresflags}})
                            end
                        end)
                    }
                end
            end
        end
    end

    -- build batchjobs for modules
    common.build_batchjobs_for_modules(modulesjobs, batchjobs, flushjob)
end

-- build module files for batchcmds
function build_modules_for_batchcmds(target, batchcmds, objectfiles, modules, opt)
    local compinst = target:compiler("cxx")
    local cachedir = common.modules_cachedir(target)
    local modulecachepathflag = get_modulecachepathflag(target)
    local modulefileflag = get_modulefileflag(target)

    -- build modules
    local depmtime = 0
    local common_args = {path(cachedir, function (p) return modulecachepathflag .. p end)}
    for _, objectfile in ipairs(objectfiles) do
        local module = modules[objectfile]
        if module then
            if module.provides then
                local name, provide
                for k, v in pairs(module.provides) do
                    name = k
                    provide = v
                    break
                end
                local bmifile = provide.bmi
                local args = {"-c", "-x", "c++-module", "--precompile", path(provide.sourcefile), "-o", path(bmifile)}
                local requiresflags
                if module.requires then
                    requiresflags = get_requiresflags(target, module.requires)
                end
                batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.module.bmi %s", name)
                batchcmds:mkdir(path.directory(objectfile))
                batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_args, requiresflags or {}, args))
                batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_args, requiresflags or {}, path(bmifile), {"-c", "-o", path(objectfile)}))
                batchcmds:add_depfiles(provide.sourcefile)
                _add_module_to_mapper(target, name, bmifile)
                depmtime = math.max(depmtime, os.mtime(bmifile))
            else
                if module.requires then
                    local requiresflags = get_requiresflags(target, module.requires)
                    if requiresflags then
                        target:fileconfig_add(module.cppfile, {force = {cxxflags = requiresflags}})
                    end
                end
            end
        end
    end
    batchcmds:set_depmtime(depmtime)
    _flush_mapper(target)
end

function get_bmi_extension()
    return ".pcm"
end

function get_modulesflag(target)
    local modulesflag = _g.modulesflag
    if modulesflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fmodules", "cxxflags", {flagskey = "clang_modules"}) then
            modulesflag = "-fmodules"
        end
        if not modulesflag then
            if compinst:has_flags("-fmodules-ts", "cxxflags", {flagskey = "clang_modules_ts"}) then
                modulesflag = "-fmodules-ts"
            end
        end
        assert(modulesflag, "compiler(clang): does not support c++ module!")
        _g.modulesflag = modulesflag or false
    end
    return modulesflag or nil
end

function get_builtinmodulemapflag(target)
    local builtinmodulemapflag = _g.builtinmodulemapflag
    if builtinmodulemapflag == nil then
        -- this flag seems clang on mingw doesn't distribute it
        -- @see https://github.com/xmake-io/xmake/pull/2833
        if not target:is_plat("mingw") then
            local compinst = target:compiler("cxx")
            if compinst:has_flags("-fbuiltin-module-map", "cxxflags", {flagskey = "clang_builtin_module_map"}) then
                builtinmodulemapflag = "-fbuiltin-module-map"
            end
            assert(builtinmodulemapflag, "compiler(clang): does not support c++ module!")
        end
        _g.builtinmodulemapflag = builtinmodulemapflag or false
    end
    return builtinmodulemapflag or nil
end

function get_implicitmodulesflag(target)
    local implicitmodulesflag = _g.implicitmodulesflag
    if implicitmodulesflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fimplicit-modules", "cxxflags", {flagskey = "clang_implicit_modules"}) then
            implicitmodulesflag = "-fimplicit-modules"
        end
        assert(implicitmodulesflag, "compiler(clang): does not support c++ module!")
        _g.implicitmodulesflag = implicitmodulesflag or false
    end
    return implicitmodulesflag or nil
end

function get_noimplicitmodulemapsflag(target)
    local noimplicitmodulemapsflag = _g.noimplicitmodulemapsflag
    if noimplicitmodulemapsflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fno-implicit-module-maps", "cxxflags", {flagskey = "clang_no_implicit_module_maps"}) then
            noimplicitmodulemapsflag = "-fno-implicit-module-maps"
        end
        assert(noimplicitmodulemapsflag, "compiler(clang): does not support c++ module!")
        _g.noimplicitmodulemapsflag = noimplicitmodulemapsflag or false
    end
    return noimplicitmodulemapsflag or nil
end

function get_prebuiltmodulepathflag(target)
    local prebuiltmodulepathflag = _g.prebuiltmodulepathflag
    if prebuiltmodulepathflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fprebuilt-module-path=" .. os.tmpdir(), "cxxflags", {flagskey = "clang_prebuild_module_path"}) then
            prebuiltmodulepathflag = "-fprebuilt-module-path="
        end
        assert(prebuiltmodulepathflag, "compiler(clang): does not support c++ module!")
        _g.prebuiltmodulepathflag = prebuiltmodulepathflag or false
    end
    return prebuiltmodulepathflag or nil
end

function get_modulecachepathflag(target)
    local modulecachepathflag = _g.modulecachepathflag
    if modulecachepathflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fmodules-cache-path=" .. os.tmpdir(), "cxxflags", {flagskey = "clang_modules_cache_path"}) then
            modulecachepathflag = "-fmodules-cache-path="
        end
        assert(modulecachepathflag, "compiler(clang): does not support c++ module!")
        _g.modulecachepathflag = modulecachepathflag or false
    end
    return modulecachepathflag or nil
end

function get_modulefileflag(target)
    local modulefileflag = _g.modulefileflag
    if modulefileflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fmodule-file=" .. os.tmpfile() .. get_bmi_extension(), "cxxflags", {flagskey = "clang_module_file"}) then
            modulefileflag = "-fmodule-file="
        end
        assert(modulefileflag, "compiler(clang): does not support c++ module!")
        _g.modulefileflag = modulefileflag or false
    end
    return modulefileflag or nil
end

function has_headerunitsupport(target)
    local support_headerunits = _g.support_headerunits
    if support_headerunits == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags(get_modulesflag(target) .. " -std=c++20 -x c++-user-header", "cxxflags", {flagskey = "clang_user_header_unit_support", tryrun = true}) and
           compinst:has_flags(get_modulesflag(target) .. " -std=c++20 -x c++-system-header", "cxxflags", {flagskey = "clang_system_header_unit_support", tryrun = true}) then
            support_headerunits = true
        end
        _g.support_headerunits = support_headerunits or false
    end
    return support_headerunits or nil
end

function get_requiresflags(target, requires)
    local flags = {}
    local modulemap = _get_modulemap_from_mapper(target)
    -- add deps required module flags
    for name, _ in pairs(requires) do
        for _, dep in ipairs(target:orderdeps()) do
            local modulemap_ = _get_modulemap_from_mapper(dep)
            if modulemap_[name] then
                table.join2(flags, modulemap_[name].flag)
                table.join2(flags, modulemap_[name].deps or {})
                goto continue
            end
        end

        -- append target required module mapper flags
        if modulemap[name] then
            table.join2(flags, modulemap[name].flag)
            table.join2(flags, modulemap[name].deps or {})
            goto continue
        end

        ::continue::
    end
    if #flags > 0 then
        return table.unique(flags)
    end
end
