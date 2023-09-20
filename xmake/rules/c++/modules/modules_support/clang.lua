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
import("core.base.json")
import("core.base.semver")
import("core.tool.compiler")
import("core.project.project")
import("core.project.depend")
import("core.project.config")
import("lib.detect.find_tool")
import("utils.progress")
import("private.action.build.object", {alias = "objectbuilder"})
import("common")
import("stl_headers")

-- get bmi path
-- @see https://github.com/xmake-io/xmake/issues/4063
function _get_bmi_path(bmifile)
    if is_host("windows") then
        bmifile = bmifile:gsub(":", "_")
    end
    return bmifile
end

-- get clang path
function _get_clang_path(target)
    local clang_path = _g.clang_path
    if not clang_path then
        local program, toolname = target:tool("cxx")
        if program and (toolname == "clang" or toolname == "clangxx") then
            local clang = find_tool("clang", {program = program})
            if clang then
                clang_path = clang.program
            end
        end
        clang_path = clang_path or false
        _g.clang_path = clang_path
    end
    return clang_path or nil
end

-- get clang version
function _get_clang_version(target)
    local clang_version = _g.clang_version
    if not clang_version then
        local program, toolname = target:tool("cxx")
        if program and (toolname == "clang" or toolname == "clangxx") then
            local clang = find_tool("clang", {program = program, version = true})
            if clang then
                clang_version = clang.version
            end
        end
        clang_version = clang_version or false
        _g.clang_version = clang_version
    end
    return clang_version or nil
end

-- get clang-scan-deps
function _get_clang_scan_deps(target)
    local clang_scan_deps = _g.clang_scan_deps
    if not clang_scan_deps then
        local program, toolname = target:tool("cxx")
        if program and (toolname == "clang" or toolname == "clangxx") then
            local dir = path.directory(program)
            local basename = path.basename(program)
            local extension = path.extension(program)
            program = (basename:gsub("clang", "clang-scan-deps")) .. extension
            if dir and dir ~= "." and os.isdir(dir) then
                program = path.join(dir, program)
            end
            local result = find_tool("clang-scan-deps", {program = program, version = true})
            if result then
                clang_scan_deps = result.program
            end
        end
        clang_scan_deps = clang_scan_deps or false
        _g.clang_scan_deps = clang_scan_deps
    end
    return clang_scan_deps or nil
end

-- add a module or an header unit into the mapper
--
-- e.g
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/foo.pcm
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/iostream.pcm
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/bar.hpp.pcm
-- on LLVM >= 16
-- -fmodule-file=foo=build/.gens/Foo/rules/modules/cache/foo.pcm
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/iostream.pcm
-- -fmodule-file=build/.gens/Foo/rules/modules/cache/bar.hpp.pcm
--
function _add_module_to_mapper(target, name, bmifile, opt)
    opt = opt or {}
    local modulemap = _get_modulemap_from_mapper(target, name)
    if modulemap then
        return
    end

    local clang_version = _get_clang_version(target)
    local namedmodule = opt.namedmodule and semver.compare(clang_version, "16.0") >= 0
    local modulefileflag = get_modulefileflag(target)
    local mapflag = namedmodule and format("%s%s=%s", modulefileflag, name, bmifile) or modulefileflag .. bmifile
    modulemap = {flag = mapflag, deps = opt.deps}
    common.localcache():set2(_mapper_cachekey(target), "modulemap" .. name, modulemap)
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
function _get_modulemap_from_mapper(target, name)
    return common.localcache():get2(_mapper_cachekey(target), "modulemap" .. name) or nil
end

-- use the given stdlib? e.g. libc++ or libstdc++
function _use_stdlib(target, name)
    local stdlib = target:data("cxx.modules.stdlib") or "libstdc++"
    return stdlib == name
end

-- set stdlib flags, it will use libstdc++ if we do not set `-stdlib=`
function _set_stdlib_flags(target)
    if _use_stdlib(target, "libc++") then
        target:add("cxxflags", "-stdlib=libc++")
        target:add("ldflags", "-stdlib=libc++")
        target:add("shflags", "-stdlib=libc++")
    end
end

-- load module support for the current target
function load(target)
    local clangmodulesflag, modulestsflag, withoutflag = get_modulesflag(target)

    -- add module flags
    if not withoutflag then
        target:add("cxxflags", modulestsflag)
    end

    -- enable clang modules to emulate std modules
    if target:policy("build.c++.clang.stdmodules") then
       target:add("cxxflags", clangmodulesflag)
    end

    -- fix default visibility for functions and variables [-fvisibility] differs in PCH file vs. current file
    -- module.pcm cannot be loaded due to a configuration mismatch with the current compilation.
    --
    -- it will happen in binary target depend on library target with modules, and enable release mode at same time.
    --
    -- @see https://github.com/xmake-io/xmake/issues/3358#issuecomment-1432586767
    local dep_symbols
    local has_library_deps = false
    for _, dep in ipairs(target:orderdeps()) do
        if dep:is_shared() or dep:is_static() or dep:is_object() then
            dep_symbols = dep:get("symbols")
            has_library_deps = true
            break
        end
    end
    if has_library_deps then
        target:set("symbols", dep_symbols and dep_symbols or "none")
    end

    -- if use libc++, we need to install libc++ and libc++abi
    --
    -- on ubuntu:
    -- sudo apt install libc++-dev libc++abi-15-dev
    --
    local flags = table.join(target:get("cxxflags") or {}, get_config("cxxflags") or {})
    if table.contains(flags, "-stdlib=libc++", "clang::-stdlib=libc++") then
        target:data_set("cxx.modules.stdlib", "libc++")
    elseif table.contains(flags, "-stdlib=libstdc++", "clang::-stdlib=libstdc++") then
        target:data_set("cxx.modules.stdlib", "libstdc++")
    end
    _set_stdlib_flags(target)
end

-- get includedirs for stl headers
--
-- $ echo '#include <vector>' | clang -x c++ -E - | grep '/vector"'
-- # 1 "/usr/include/c++/11/vector" 1 3
-- # 58 "/usr/include/c++/11/vector" 3
-- # 59 "/usr/include/c++/11/vector" 3
--
function _get_toolchain_includedirs_for_stlheaders(target, includedirs, clang)
    local tmpfile = os.tmpfile() .. ".cc"
    io.writefile(tmpfile, "#include <vector>")
    local argv = {"-E", "-x", "c++", tmpfile}
    if _use_stdlib(target, "libc++") then
        table.insert(argv, 1, "-stdlib=libc++")
    end
    local result = try {function () return os.iorunv(clang, argv) end}
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

-- do compile for batchcmds
-- @note we need to use batchcmds:compilev to translate paths in compflags for generator, e.g. -Ixx
function _batchcmds_compile(batchcmds, target, flags, sourcefile)
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
    batchcmds:compilev(table.join(compflags or {}, flags), {compiler = compinst, sourcekind = "cxx"})
end

-- build module file
function _build_modulefile(target, sourcefile, opt)
    local objectfile = opt.objectfile
    local dependfile = opt.dependfile
    local compinst = compiler.load("cxx", {target = target})
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
    local dependinfo = target:is_rebuilt() and {} or (depend.load(dependfile) or {})

    -- need build this object?
    local dryrun = option.get("dry-run")
    local depvalues = {compinst:program(), compflags}
    local lastmtime = os.isfile(objectfile) and os.mtime(dependfile) or 0
    if not dryrun and not depend.is_changed(dependinfo, {lastmtime = lastmtime, values = depvalues}) then
        return
    end

    -- init flags
    local common_args = opt.common_args
    local requiresflags = opt.requiresflags
    local moduleoutputflag = get_moduleoutputflag(target)

    -- trace
    progress.show(opt.progress, "${color.build.object}compiling.module.$(mode) %s", opt.provide and opt.provide.name or sourcefile)

    local bmifile
    local compileflags = {}
    local bmiflags
    if opt.provide then
        bmifile = _get_bmi_path(opt.provide.bmifile)
        if bmifile then
            common.memcache():set2(bmifile, "compiling", true)
        end
        if moduleoutputflag then
            compileflags = table.join("-x", "c++-module", moduleoutputflag .. bmifile, requiresflags)
        else
            bmiflags = table.join("-x", "c++-module", "--precompile", compflags, common_args, requiresflags)
        end
    else
        compileflags = {"-x", "c++"}
    end

    if bmiflags then
        vprint(compinst:compcmd(sourcefile, bmifile, {compflags = bmiflags, rawargs = true}))
    end

    compileflags = table.join2(compileflags, compflags, common_args, requiresflags or {})
    vprint(compinst:compcmd(bmiflags and bmifile or sourcefile, objectfile, {compflags = compileflags, rawargs = true}))

    if not dryrun then

        -- do compile
        dependinfo.files = {}
        if bmiflags then
            assert(compinst:compile(sourcefile, bmifile, {dependinfo = dependinfo, compflags = bmiflags}))
        end
        assert(compinst:compile(bmiflags and bmifile or sourcefile, objectfile, {dependinfo = dependinfo, compflags = compileflags}))

        -- update files and values to the dependent file
        dependinfo.values = depvalues
        table.join2(dependinfo.files, sourcefile)
        table.join2(dependinfo.files, opt.requires or {})
        depend.save(dependinfo, dependfile)
    end
end

-- provide toolchain include directories for stl headerunit when p1689 is not supported
function toolchain_includedirs(target)
    local includedirs = _g.includedirs
    if includedirs == nil then
        includedirs = {}
        local clang, toolname = target:tool("cxx")
        assert(toolname:startswith("clang"))
        _get_toolchain_includedirs_for_stlheaders(target, includedirs, clang)
        local _, result = try {function () return os.iorunv(clang, {"-E", "-stdlib=libc++", "-Wp,-v", "-xc", os.nuldev()}) end}
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
    local compinst = target:compiler("cxx")
    local changed = false
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function()
            if opt.progress then
                progress.show(opt.progress, "${color.build.object}generating.module.deps %s", sourcefile)
            end

            local outputdir = common.get_outputdir(target, sourcefile)
            local jsonfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".json"))
            if has_clangscandepssupport(target) and not target:policy("build.c++.clang.fallbackscanner") then
                -- We need absolute path of clang to use clang-scan-deps
                -- See https://clang.llvm.org/docs/StandardCPlusPlusModules.html#possible-issues-failed-to-find-system-headers
                local clang_path = compinst:program()
                if not path.is_absolute(clang_path) then
                    clang_path = _get_clang_path(target) or compinst:program()
                end
                local clangscandeps = _get_clang_scan_deps(target)
                local compinst = target:compiler("cxx")
                local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
                local flags = table.join("--format=p1689", "--",
                                         clang_path, "-x", "c++", "-c", sourcefile, "-o", target:objectfile(sourcefile),
                                         compflags)
                vprint(table.concat(table.join(clangscandeps, flags), " "))
                local outdata, errdata = os.iorunv(clangscandeps, flags)
                assert(errdata, errdata)

                io.writefile(jsonfile, outdata)
            else
                common.fallback_generate_dependencies(target, jsonfile, sourcefile, function(file)
                    local compflags = compinst:compflags({sourcefile = file, target = target})
                    -- exclude -fmodule* and -std=c++/gnu++* flags because,
                    -- when they are set clang try to find bmi of imported modules but they don't exists a this point of compilation
                    table.remove_if(compflags, function(_, flag)
                        return flag:startswith("-fmodule") or flag:startswith("-std=c++") or flag:startswith("-std=gnu++")
                    end)
                    local ifile = path.translate(path.join(outputdir, path.filename(file) .. ".i"))
                    os.vrunv(compinst:program(), table.join(compflags, {"-E", "-x", "c++", file, "-o", ifile}))
                    local content = io.readfile(ifile)
                    os.rm(ifile)
                    return content
                end)
            end
            changed = true

            local rawdependinfo = io.readfile(jsonfile)
            if rawdependinfo then
                local dependinfo = json.decode(rawdependinfo)
                if target:data("cxx.modules.stdlib") == nil then
                    local has_std_modules = false
                    for _, r in ipairs(dependinfo.rules) do
                        for _, required in ipairs(r.requires) do
                            -- it may be `std:utility`, ..
                            -- @see https://github.com/xmake-io/xmake/issues/3373
                            local logical_name = required["logical-name"]
                            if logical_name and (logical_name == "std" or logical_name:startswith("std.") or logical_name:startswith("std:")) then
                                has_std_modules = true
                                break
                            end
                        end

                        if has_std_modules then
                            break
                        end
                    end
                    if has_std_modules then

                        -- we need clang >= 17.0 or use clang stdmodules if the current target contains std module
                        local clang_version = _get_clang_version(target)
                        assert((clang_version and semver.compare(clang_version, "17.0") >= 0) or target:policy("build.c++.clang.stdmodules"),
                               [[On llvm <= 16 standard C++ modules are not supported ;
                               they can be emulated through clang modules and supported only on libc++ ;
                               please add -stdlib=libc++ cxx flag or disable strict mode]])

                        -- we use libc++ by default if we do not explicitly specify -stdlib:libstdc++
                        target:data_set("cxx.modules.stdlib", "libc++")
                        _set_stdlib_flags(target)
                    end
                end
            end

            return {moduleinfo = rawdependinfo}
        end, {dependfile = dependfile, files = {sourcefile}, changed = target:is_rebuilt()})
    end
    return changed
end

-- generate target stl header units for batchjobs
function generate_stl_headerunits_for_batchjobs(target, batchjobs, headerunits, opt)
    local compinst = target:compiler("cxx")
    local stlcachedir = common.stlmodules_cachedir(target, {mkdir = true})
    local modulecachepathflag = get_modulecachepathflag(target)
    assert(has_headerunitsupport(target), "compiler(clang): does not support c++ header units!")

    -- flush job
    local flushjob = batchjobs:addjob(target:name() .. "_stl_headerunits_flush_mapper", function(index, total)
        _flush_mapper(target)
    end, {rootjob = opt.rootjob})

    -- build headerunits
    for _, headerunit in ipairs(headerunits) do
        local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_extension())
        if not os.isfile(bmifile) then
            batchjobs:addjob(headerunit.name, function (index, total)
                depend.on_changed(function()
                    -- don't build same header unit at the same time
                    if not common.memcache():get2(headerunit.name, "building") then
                        common.memcache():set2(headerunit.name, "building", true)
                        progress.show((index * 100) / total, "${color.build.object}compiling.headerunit.$(mode) %s", headerunit.name)
                        local args = {modulecachepathflag .. stlcachedir, "-c", "-Wno-everything", "-o", bmifile, "-x", "c++-system-header", headerunit.name}
                        os.vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))
                    end

                end, {dependfile = target:dependfile(bmifile), files = {headerunit.path}, changed = target:is_rebuilt()})

                -- libc++ have a builtin module mapper
                if not _use_stdlib(target, "libc++") then
                    _add_module_to_mapper(target, headerunit.name, bmifile)
                end
            end, {rootjob = flushjob})
        end
    end
end

-- generate target stl header units for batchcmds
function generate_stl_headerunits_for_batchcmds(target, batchcmds, headerunits, opt)
    local stlcachedir = common.stlmodules_cachedir(target, {mkdir = true})
    local modulecachepathflag = get_modulecachepathflag(target)
    assert(has_headerunitsupport(target), "compiler(clang): does not support c++ header units!")

    -- build headerunits
    local depmtime = 0
    for _, headerunit in ipairs(headerunits) do
        local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_extension())
        -- don't build same header unit at the same time
        if not common.memcache():get2(headerunit.name, "building") then
            common.memcache():set2(headerunit.name, "building", true)
            local flags = {
                path(stlcachedir, function (p) return modulecachepathflag .. p end),
                "-c", "-Wno-everything", "-o", path(bmifile), "-x", "c++-system-header", headerunit.name}
            batchcmds:show_progress(opt.progress, "${color.build.object}compiling.headerunit.$(mode) %s", headerunit.name)
            _batchcmds_compile(batchcmds, target, flags)
        end
        -- libc++ have a builtin module mapper
        if not _use_stdlib(target, "libc++") then
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
    local cachedir = common.modules_cachedir(target, {mkdir = true})
    local modulecachepathflag = get_modulecachepathflag(target)

    -- flush job
    local flushjob = batchjobs:addjob(target:name() .. "_user_headerunits_flush_mapper", function(index, total)
        _flush_mapper(target)
    end, {rootjob = opt.rootjob})

    -- build headerunits
    for _, headerunit in ipairs(headerunits) do
        local file = path.relative(headerunit.path, target:scriptdir())
        local objectfile = target:objectfile(file)

        local outputdir = common.get_outputdir(target, headerunit.path)
        local bmifilename = path.basename(objectfile) .. get_bmi_extension()
        local bmifile = path.join(outputdir, bmifilename)
        batchjobs:addjob(headerunit.name, function (index, total)
            depend.on_changed(function()
                progress.show((index * 100) / total, "${color.build.object}compiling.headerunit.$(mode) %s", headerunit.name)
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

            end, {dependfile = target:dependfile(bmifile), files = {headerunit.path}, changed = target:is_rebuilt()})
            _add_module_to_mapper(target, headerunit.name, bmifile)
        end, {rootjob = flushjob})
    end
end

-- generate target user header units for batchcmds
function generate_user_headerunits_for_batchcmds(target, batchcmds, headerunits, opt)
    assert(has_headerunitsupport(target), "compiler(clang): does not support c++ header units!")

    -- get cachedirs
    local cachedir = common.modules_cachedir(target, {mkdir = true})
    local modulecachepathflag = get_modulecachepathflag(target)

    -- build headerunits
    local depmtime = 0
    for _, headerunit in ipairs(headerunits) do
        local file = path.relative(headerunit.path, target:scriptdir())
        local objectfile = target:objectfile(file)

        local outputdir = common.get_outputdir(target, headerunit.path)
        batchcmds:mkdir(outputdir)

        local bmifilename = path.basename(objectfile) .. get_bmi_extension()
        local bmifile = (outputdir and path.join(outputdir, bmifilename) or bmifilename)
        batchcmds:mkdir(path.directory(objectfile))

        local flags = {path(cachedir, function (p) return modulecachepathflag .. p end), "-c", "-o", path(bmifile)}
        if headerunit.type == ":quote" then
            table.join2(flags, {"-I", path(headerunit.path):directory(), "-x", "c++-user-header", path(headerunit.path)})
        elseif headerunit.type == ":angle" then
            table.join2(flags, {"-x", "c++-system-header", headerunit.name})
        end

        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.headerunit.$(mode) %s", headerunit.name)
        _batchcmds_compile(batchcmds, target, flags)
        batchcmds:add_depfiles(headerunit.path)

        _add_module_to_mapper(target, headerunit.name, bmifile)

        depmtime = math.max(depmtime, os.mtime(bmifile))
    end
    batchcmds:set_depmtime(depmtime)
    _flush_mapper(target)
end

-- build module files for batchjobs
function build_modules_for_batchjobs(target, batchjobs, objectfiles, modules, opt)

    -- get flags
    local cachedir = common.modules_cachedir(target, {mkdir = true})
    local modulecachepathflag = get_modulecachepathflag(target)

    -- flush job
    local flushjob = batchjobs:addjob(target:name() .. "_modules", function(index, total)
        _flush_mapper(target)
    end, {rootjob = opt.rootjob})

    -- build modules
    local common_args = {modulecachepathflag .. cachedir}
    local modulesjobs = {}
    for _, objectfile in ipairs(objectfiles) do
        local module = modules[objectfile]
        if module then
            local cppfile = module.cppfile
            local name, provide
            if module.provides then
                -- assume there that provides is only one, until we encounter the case
                local length = 0
                for k, v in pairs(module.provides) do
                    length = length + 1
                    name = k
                    provide = v
                    cppfile = provide.sourcefile
                    if length > 1 then
                        raise("multiple provides are not supported now!")
                    end
                    break
                end
            end
            local moduleinfo = table.copy(provide) or {}

            if provide then
                local fileconfig = target:fileconfig(cppfile)
                if fileconfig and fileconfig.install then
                    batchjobs:addjob(name .. "_metafile", function(index, total)
                        local metafilepath = common.get_metafile(target, cppfile)
                        depend.on_changed(function()
                            progress.show(opt.progress, "${color.build.object}generating.module.metadata %s", name)
                            local metadata = common.generate_meta_module_info(target, name, cppfile, module.requires)
                            json.savefile(metafilepath, metadata)
                        end, {dependfile = target:dependfile(metafilepath), files = {cppfile}, changed = target:is_rebuilt()})
                    end, {rootjob = flushjob})
                end
            end

            table.join2(moduleinfo, {
                name = name or cppfile,
                deps = table.keys(module.requires or {}),
                sourcefile = cppfile,
                job = batchjobs:newjob(name or cppfile, function(index, total)
                    -- @note we add it at the end to ensure that the full modulemap are already stored in the mapper
                    local requiresflags
                    local requires
                    if module.requires then
                        requiresflags = get_requiresflags(target, module.requires)
                        requires = get_requires(target, module.requires)
                    end

                    if provide or common.has_module_extension(cppfile) then
                        local bmifile = _get_bmi_path(provide and provide.bmi)
                        if not common.memcache():get2(name or cppfile, "compiling") then
                            if name and module.external then
                                common.memcache():set2(name or cppfile, "compiling", true)
                            end
                            _build_modulefile(target, provide and provide.sourcefile or cppfile, {
                                objectfile = objectfile,
                                dependfile = target:dependfile(bmifile or objectfile),
                                provide = provide and {bmifile = bmifile, name = name},
                                common_args = common_args,
                                requiresflags = requiresflags,
                                requires = requires,
                                progress = (index * 100) / total})
                        end
                        target:add("objectfiles", objectfile)

                        if provide then
                            _add_module_to_mapper(target, name, bmifile, {deps = requiresflags, namedmodule = true})
                        end
                    elseif requiresflags then
                        local cxxflags = {}
                        for _, flag in ipairs(requiresflags) do
                            -- we need to wrap flag to support flag with space
                            if type(flag) == "string" and flag:find(" ", 1, true) then
                                table.insert(cxxflags, {flag})
                            else
                                table.insert(cxxflags, flag)
                            end
                        end
                        target:fileconfig_add(cppfile, {force = {cxxflags = cxxflags}})
                        -- force rebuild .cpp file if any of its module dependency is rebuilt
                        local rebuild = false
                        for _, requiredfile in ipairs(requires) do
                            if common.memcache():get2(requiredfile, "compiling") == true then
                                rebuild = true
                                break
                            end
                        end
                        if rebuild then
                           os.rm(target:objectfile(cppfile))
                        end
                    end
                end)})
            modulesjobs[name or cppfile] = moduleinfo
        end
    end

    -- build batchjobs for modules
    common.build_batchjobs_for_modules(modulesjobs, batchjobs, flushjob)
end

-- build module files for batchcmds
function build_modules_for_batchcmds(target, batchcmds, objectfiles, modules, opt)
    local cachedir = common.modules_cachedir(target, {mkdir = true})
    local modulecachepathflag = get_modulecachepathflag(target)

    -- build modules
    local depmtime = 0
    for _, objectfile in ipairs(objectfiles) do
        local module = modules[objectfile]
        if module then
            local cppfile = module.cppfile
            local name, provide
            if module.provides then
                local length = 0
                for k, v in pairs(module.provides) do
                    length = length + 1
                    name = k
                    provide = v
                    cppfile = provide.sourcefile
                    if length > 1 then
                        raise("multiple provides are not supported now!")
                    end
                    break
                end
            end
            local requiresflags
            if module.requires then
                requiresflags = get_requiresflags(target, module.requires)
            end

            local flags = table.join({path(cachedir, function (p) return modulecachepathflag .. p end)}, requiresflags or {})
            if provide or common.has_module_extension(cppfile) then
                local file = provide and path(provide.bmi) or path(cppfile)

                batchcmds:show_progress(opt.progress, "${color.build.object}compiling.module.$(mode) %s", name or cppfile)
                batchcmds:mkdir(path.directory(objectfile))
                if provide then
                    _batchcmds_compile(batchcmds, target, table.join(flags,
                        {"-x", "c++-module", "--precompile", "-c", path(cppfile), "-o", path(provide.bmi)}), cppfile)
                    _add_module_to_mapper(target, name, provide.bmi, {namedmodule = true})
                    -- add requiresflags to module. it will be used for project generation
                    target:fileconfig_add(cppfile, {force = {cxxflags = requiresflags}})
                end
                _batchcmds_compile(batchcmds, target, table.join(flags,
                    not provide and {"-x", "c++"} or {}, {"-c", file, "-o", path(objectfile)}), file)
                target:add("objectfiles", objectfile)
            elseif requiresflags then
                local cxxflags = {}
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

            batchcmds:add_depfiles(cppfile)
            depmtime = math.max(depmtime, os.mtime(objectfile))
        end
    end
    batchcmds:set_depmtime(depmtime)
    _flush_mapper(target)
end

-- not supported atm
function get_stdmodules(target)
    local modules = {}
    return modules
end

function get_bmi_extension()
    return ".pcm"
end

function get_modulesflag(target)
    local clangmodulesflag = _g.clangmodulesflag
    local modulestsflag = _g.modulestsflag
    local withoutflag = _g.withoutflag
    if clangmodulesflag == nil and modulestsflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fmodules", "cxxflags", {flagskey = "clang_modules"}) then
            clangmodulesflag = "-fmodules"
        end
        if compinst:has_flags("-fmodules-ts", "cxxflags", {flagskey = "clang_modules_ts"}) then
            modulestsflag = "-fmodules-ts"
        end
        local clang_version = _get_clang_version(target)
        withoutflag = semver.compare(clang_version, "16.0") >= 0
        assert(withoutflag or modulestsflag, "compiler(clang): does not support c++ module!")
        _g.clangmodulesflag = clangmodulesflag or false
        _g.modulestsflag = modulestsflag or false
        _g.withoutflag = withoutflag or false
    end
    return clangmodulesflag or nil, modulestsflag or nil, withoutflag or nil
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

function get_implicitmodulemapsflag(target)
    local implicitmodulemapsflag = _g.implicitmodulemapsflag
    if implicitmodulemapsflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fimplicit-module-maps", "cxxflags", {flagskey = "clang_implicit_module_map"}) then
            implicitmodulemapsflag = "-fimplicit-module-maps"
        end
        assert(implicitmodulemapsflag, "compiler(clang): does not support c++ module!")
        _g.implicitmodulemapsflag = implicitmodulemapsflag or false
    end
    return implicitmodulemapsflag or nil
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
        local _, modulestsflag, withoutflag = get_modulesflag(target)
        modulestsflag = withoutflag and "" or modulestsflag
        if compinst:has_flags(modulestsflag .. " -std=c++20 -x c++-user-header", "cxxflags", {
                snippet = "inline int foo() { return 0; }",
                flagskey = "clang_user_header_unit_support",
                tryrun = true}) and
           compinst:has_flags(modulestsflag .. " -std=c++20 -x c++-system-header", "cxxflags", {
                snippet = "inline int foo() { return 0; }",
                flagskey = "clang_system_header_unit_support",
                tryrun = true}) then
            support_headerunits = true
        end
        _g.support_headerunits = support_headerunits or false
    end
    return support_headerunits or nil
end

function has_clangscandepssupport(target)
    local support_clangscandeps = _g.support_clangscandeps
    if support_clangscandeps == nil then
        local clangscandeps = _get_clang_scan_deps(target)
        local clang_version = _get_clang_version(target)
        if clangscandeps and clang_version and semver.compare(clang_version, "16.0") >= 0 then
            support_clangscandeps = true
        end
        _g.support_clangscandeps = support_clangscandeps or false
    end
    return support_clangscandeps or nil
end

function get_moduleoutputflag(target)
    local moduleoutputflag = _g.moduleoutputflag
    if moduleoutputflag == nil then
        local compinst = target:compiler("cxx")
        local clang_version = _get_clang_version(target)
        if compinst:has_flags("-fmodule-output=", "cxxflags", {flagskey = "clang_module_output", tryrun = true}) and
            semver.compare(clang_version, "16.0") >= 0 then
            moduleoutputflag = "-fmodule-output="
        end
        _g.moduleoutputflag = moduleoutputflag or false
    end
    return moduleoutputflag or nil
end

function get_requires(target, requires)
  local flags = get_requiresflags(target, requires)
  local requires
  for _, flag in ipairs(flags) do
    requires = requires or {}
    table.insert(requires, flag:split("=")[3])
  end

  return requires
end

function get_requiresflags(target, requires)
    local flags = {}
    -- add deps required module flags
    local already_mapped_modules = {}
    for name, _ in table.orderpairs(requires) do
        -- if already in flags, continue
        if already_mapped_modules[name] then
            goto continue
        end

        for _, dep in ipairs(target:orderdeps()) do
            local modulemap_ = _get_modulemap_from_mapper(dep, name)
            if modulemap_ then
                already_mapped_modules[name] = true
                table.insert(flags, modulemap_.flag)
                if modulemap_.deps then
                    table.join2(flags, modulemap_.deps)
                end
                goto continue
            end
        end

        -- append target required module mapper flags
        local modulemap = _get_modulemap_from_mapper(target, name)
        if modulemap then
            already_mapped_modules[name] = true
            table.insert(flags, modulemap.flag)
            if modulemap.deps then
                table.join2(flags, modulemap.deps)
            end
            goto continue
        end

        ::continue::
    end
    if #flags > 0 then
        return table.unique(flags)
    end
end
