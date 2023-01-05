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
-- @file        gcc.lua
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

-- get and create the path of module mapper
function _get_module_mapper(target)
    local mapper_file = path.join(config.buildir(), target:name(), "mapper.txt")
    if not os.isfile(mapper_file) then
        io.writefile(mapper_file, "")
    end
    return mapper_file
end

-- add a module or header unit into the mapper
--
-- e.g
-- /usr/include/c++/11/iostream build/.gens/stl_headerunit/linux/x86_64/release/stlmodules/cache/iostream.gcm
-- hello build/.gens/stl_headerunit/linux/x86_64/release/rules/modules/cache/hello.gcm
--
function _add_module_to_mapper(file, module, bmi)
    for line in io.lines(file) do
        if line:startswith(module .. " ") then
            return false
        end
    end
    local f = io.open(file, "a")
    f:print("%s %s", module, bmi)
    f:close()
    return true
end

-- get a module from mapper
function _get_module_from_mapper(file, module)
    for line in io.lines(file) do
        if line:startswith(module .. " ") then
            return line:split(" ", {plain = true})
        end
    end
end

-- load module support for the current target
function load(target)
    local modulesflag = get_modulesflag(target)
    local modulemapperflag = get_modulemapperflag(target)
    if os.isfile(_get_module_mapper(target)) then
        os.rm(_get_module_mapper(target))
    end
    target:add("cxxflags", {modulesflag, modulemapperflag .. path.translate(_get_module_mapper(target))}, {force = true, expand = false})
    -- fix cxxabi issue, @see https://github.com/xmake-io/xmake/issues/2716#issuecomment-1225057760
    target:add("cxxflags", "-D_GLIBCXX_USE_CXX11_ABI=0")
end

-- get includedirs for stl headers
--
-- $ echo '#include <vector>' | gcc -x c++ -E - | grep '/vector"'
-- # 1 "/usr/include/c++/11/vector" 1 3
-- # 58 "/usr/include/c++/11/vector" 3
-- # 59 "/usr/include/c++/11/vector" 3
--
function _get_toolchain_includedirs_for_stlheaders(includedirs, gcc)
    local tmpfile = os.tmpfile() .. ".cc"
    io.writefile(tmpfile, "#include <vector>")
    local result = try {function () return os.iorunv(gcc, {"-E", "-x", "c++", tmpfile}) end}
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
-- @note we need use batchcmds:compilev to translate paths in compflags for generator, e.g. -Ixx
function _batchcmds_compile(batchcmds, target, flags)
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({target = target})
    batchcmds:compilev(table.join(compflags or {}, flags), {compiler = compinst, sourcekind = "cxx"})
end

-- build module file
function _build_modulefile(target, sourcefile, opt)
    local objectfile = opt.objectfile
    local dependfile = opt.dependfile
    local compinst = compiler.load("cxx", {target = target})
    local compflags = table.join("-x", "c++", compinst:compflags({target = target}))
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

    -- need build this object?
    local dryrun = option.get("dry-run")
    local depvalues = {compinst:program(), compflags}
    local lastmtime = os.isfile(objectfile) and os.mtime(dependfile) or 0
    if not dryrun and not depend.is_changed(dependinfo, {lastmtime = lastmtime, values = depvalues}) then
        return
    end

    -- trace
    progress.show(opt.progress, "${color.build.object}compiling.module.$(mode) %s", opt.name)
    vprint(compinst:compcmd(sourcefile, objectfile, {compflags = compflags, rawargs = true}))

    if not dryrun then

        -- do compile
        dependinfo.files = {}
        assert(compinst:compile(sourcefile, objectfile, {dependinfo = dependinfo, compflags = compflags}))

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
        local gcc, toolname = target:tool("cxx")
        assert(toolname == "gcc")
        _get_toolchain_includedirs_for_stlheaders(includedirs, gcc)
        local _, result = try {function () return os.iorunv(gcc, {"-E", "-Wp,-v", "-xc", os.nuldev()}) end}
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
    local cachedir = common.modules_cachedir(target)
    local compinst = target:compiler("cxx")
    local common_args = {"-E", "-x", "c++"}
    local depformatflag = get_depflag(target, "p1689r5") or get_depflag(target, "trtbd")
    local depfileflag = get_depfileflag(target)
    local depoutputflag = get_depoutputflag(target)
    local changed = false
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function()
            if opt.progress then
                progress.show(opt.progress, "${color.build.object}generating.module.deps %s", sourcefile)
            end

            local outputdir = path.translate(path.join(cachedir, path.directory(path.relative(sourcefile, projectdir))))
            if not os.isdir(outputdir) then
                os.mkdir(outputdir)
            end

            local jsonfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".json"))
            if depformatflag and depfileflag and depoutputflag then
                local ifile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".i"))
                local dfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".d"))
                local args = {sourcefile, "-MT", jsonfile, "-MD", "-MF", dfile, depformatflag, depfileflag .. jsonfile, depoutputflag .. target:objectfile(sourcefile), "-o", ifile}
                local compflags = compinst:compflags({target = target})
                -- module mapper flag force gcc to check the imports but this is not wanted at this stage
                local modulemapperflag = get_modulemapperflag(target) .. path.translate(_get_module_mapper(target))
                table.remove(compflags, table.unpack(table.find(compflags, modulemapperflag)))
                os.vrunv(compinst:program(), table.join(compflags, common_args, args))
                os.rm(ifile)
                os.rm(dfile)
            else
                common.fallback_generate_dependencies(target, jsonfile, sourcefile, function(file)
                    local compinst = target:compiler("cxx")
                    local defines = {}
                    for _, define in ipairs(target:get("defines")) do
                        table.insert(defines, "-D" .. define)
                    end
                    local includedirs = table.join({}, target:get("includedirs"))
                    for _, dep in ipairs(target:orderdeps()) do
                        local includedir = dep:get("sysincludedirs") or dep:get("includedirs")
                        if includedir then
                            table.join2(includedirs, includedir)
                        end
                    end
                    for _, pkg in pairs(target:pkgs()) do
                        local includedir = pkg:get("sysincludedirs") or pkg:get("includedirs")
                        if includedir then
                            table.join2(includedirs, includedir)
                        end
                    end
                    for i, includedir in pairs(includedirs) do
                        includedirs[i] = "-I" .. includedir
                    end
                    local ifile = path.translate(path.join(outputdir, path.filename(file) .. ".i"))
                    os.vrunv(compinst:program(), table.join(common_args, includedirs, defines, {get_cppversionflag(target), file,  "-o", ifile}))
                    local content = io.readfile(ifile)
                    os.rm(ifile)
                    return content
                end)
            end
            changed = true

            local dependinfo = io.readfile(jsonfile)
            return { moduleinfo = dependinfo }
        end, {dependfile = dependfile, files = {sourcefile}})
    end
    return changed
end

-- generate target stl header units for batchjobs
function generate_stl_headerunits_for_batchjobs(target, batchjobs, headerunits, opt)
    local compinst = target:compiler("cxx")
    local mapper_file = _get_module_mapper(target)
    local stlcachedir = common.stlmodules_cachedir(target, {mkdir = true})
    local modulemapperflag = get_modulemapperflag(target)

    -- build headerunits
    local projectdir = os.projectdir()
    for _, headerunit in ipairs(headerunits) do
        local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_extension())
        if not os.isfile(bmifile) then
            batchjobs:addjob(headerunit.name, function (index, total)
                depend.on_changed(function()
                    progress.show((index * 100) / total, "${color.build.object}compiling.headerunit.$(mode) %s", headerunit.name)
                    local args = {"-c", "-x", "c++-system-header", headerunit.name}
                    local flags = table.join(compinst:compflags({target = target}), args)
                    -- we need to support reading and writing mapperfile in parallel, otherwise it will be broken
                    -- @see tests/c++/modules/stl_headerunit_cpp_only
                    local mapper_file_tmp = os.tmpfile()
                    os.cp(mapper_file, mapper_file_tmp)
                    _add_module_to_mapper(mapper_file_tmp, headerunit.path, path.absolute(bmifile, projectdir))
                    for idx, flag in ipairs(flags) do
                        if flag:startswith(modulemapperflag) then
                            flags[idx] = modulemapperflag .. mapper_file_tmp
                            break
                        end
                    end
                    os.vrunv(compinst:program(), flags)
                    _add_module_to_mapper(mapper_file, headerunit.path, path.absolute(bmifile, projectdir))
                    os.tryrm(mapper_file_tmp)
                end, {dependfile = target:dependfile(bmifile), files = {headerunit.path}})
            end, {rootjob = opt.rootjob})
        else
            _add_module_to_mapper(mapper_file, headerunit.path, path.absolute(bmifile, projectdir))
        end
    end
end

-- generate target stl header units for batchcmds
function generate_stl_headerunits_for_batchcmds(target, batchcmds, headerunits, opt)
    local mapper_file = _get_module_mapper(target)
    local stlcachedir = common.stlmodules_cachedir(target, {mkdir = true})

    -- build headerunits
    local projectdir = os.projectdir()
    local depmtime = 0
    for _, headerunit in ipairs(headerunits) do
        local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_extension())
        if not os.isfile(bmifile) then
            local flags = {"-c", "-x", "c++-system-header", headerunit.name}
            batchcmds:show_progress(opt.progress, "${color.build.object}compiling.headerunit.$(mode) %s", headerunit.name)
            _batchcmds_compile(batchcmds, target, flags)
        end
        batchcmds:add_depfiles(headerunit.path)
        _add_module_to_mapper(mapper_file, headerunit.path, path.absolute(bmifile, projectdir))
        depmtime = math.max(depmtime, os.mtime(bmifile))
    end
    batchcmds:set_depmtime(depmtime)
end

-- generate target user header units for batchjobs
function generate_user_headerunits_for_batchjobs(target, batchjobs, headerunits, opt)
    local compinst = target:compiler("cxx")
    local mapper_file = _get_module_mapper(target)
    local cachedir = common.modules_cachedir(target)

    -- build headerunits
    local projectdir = os.projectdir()
    for _, headerunit in ipairs(headerunits) do
        local file = path.relative(headerunit.path, projectdir)
        local objectfile = target:objectfile(file)
        local outputdir
        local headerunit_path
        if headerunit.type == ":quote" then
            outputdir = path.join(cachedir, path.directory(path.relative(headerunit.path, projectdir)))
        else
            outputdir = path.join(cachedir, path.directory(headerunit.path))
        end
        local bmifilename = path.basename(objectfile) .. get_bmi_extension()
        local bmifile = (outputdir and path.join(outputdir, bmifilename) or bmifilename)
        if headerunit.type == ":quote" then
            headerunit_path = path.join(".", path.relative(headerunit.path, projectdir))
        elseif headerunit.type == ":angle" then
            -- if path is relative then its a subtarget path
            headerunit_path = path.is_absolute(headerunit.path) and headerunit.path or path.join(".", headerunit.path)
        end
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
                local args = { "-c" }
                if headerunit.type == ":quote" then
                    table.join2(args, { "-I", path.directory(path.relative(headerunit.path, projectdir)), "-x", "c++-user-header", headerunit.name })
                elseif headerunit.type == ":angle" then
                    table.join2(args, { "-x", "c++-system-header", headerunit.name })
                end
                os.vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))

            end, {dependfile = target:dependfile(bmifile), files = {headerunit.path}})
        end, {rootjob = opt.rootjob})
        _add_module_to_mapper(mapper_file, headerunit_path, path.absolute(bmifile, projectdir))
    end
end

-- generate target user header units for batchcmds
function generate_user_headerunits_for_batchcmds(target, batchcmds, headerunits, opt)
    local mapper_file = _get_module_mapper(target)
    local cachedir = common.modules_cachedir(target)

    -- build headerunits
    local projectdir = os.projectdir()
    local depmtime = 0
    for _, headerunit in ipairs(headerunits) do
        local file = path.relative(headerunit.path, projectdir)
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

        local flags = {"-c"}
        local headerunit_path
        if headerunit.type == ":quote" then
            table.join2(flags, {"-I", path(path.relative(headerunit.path, projectdir)):directory(), "-x", "c++-user-header", headerunit.name})
            headerunit_path = path.join(".", path.relative(headerunit.path, projectdir))
        elseif headerunit.type == ":angle" then
            table.join2(flags, {"-x", "c++-system-header", headerunit.name})
            -- if path is relative then its a subtarget path
            headerunit_path = path.is_absolute(headerunit.path) and headerunit.path or path.join(".", headerunit.path)
        end

        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.headerunit.$(mode) %s", headerunit.name)
        _batchcmds_compile(batchcmds, target, flags)
        batchcmds:add_depfiles(headerunit.path)

        _add_module_to_mapper(mapper_file, headerunit_path, path.absolute(bmifile, projectdir))
        depmtime = math.max(depmtime, os.mtime(bmifile))
    end
    batchcmds:set_depmtime(depmtime)
end

-- build module files for batchjobs
function build_modules_for_batchjobs(target, batchjobs, objectfiles, modules, opt)
    local mapper_file = _get_module_mapper(target)

    -- build modules
    local projectdir = os.projectdir()
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
            local dependfile = (provide and provide.bmi) and target:dependfile(provide.bmi) or target:dependfile(objectfile)
            table.join2(moduleinfo, {
                name = name or cppfile,
                deps = table.keys(module.requires or {}),
                sourcefile = cppfile,
                job = batchjobs:newjob(name or cppfile, function(index, total)
                    -- append dependencies module now to ensures deps modulemap is filled
                    for required, _ in pairs(module.requires) do
                        local m
                        for _, dep in ipairs(target:orderdeps()) do
                            m = _get_module_from_mapper(_get_module_mapper(dep), required)
                            if m then
                                break
                            end
                        end
                        if m then
                            _add_module_to_mapper(mapper_file, m[1], m[2])
                            break
                        end
                    end

                    if provide or common.has_module_extension(cppfile) then
                        _build_modulefile(target, cppfile, {
                            objectfile = objectfile,
                            dependfile = dependfile,
                            name = name or cppfile,
                            progress = (index * 100) / total})
                        target:add("objectfiles", objectfile)
                    end
                end)})
            if provide then
                _add_module_to_mapper(mapper_file, name, path.absolute(provide.bmi, projectdir))
            end
            modulesjobs[name or cppfile] = moduleinfo
        end
    end

    -- build batchjobs for modules
    common.build_batchjobs_for_modules(modulesjobs, batchjobs, opt.rootjob)
end

-- build module files for batchcmds
function build_modules_for_batchcmds(target, batchcmds, objectfiles, modules, opt)
    local modulemapperflag = get_modulemapperflag(target)
    local mapper_file = _get_module_mapper(target)

    -- build modules
    local projectdir = os.projectdir()
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
            -- append dependencies module now to ensures deps modulemap is filled
            for required, _ in pairs(module.requires) do
                local m
                for _, dep in ipairs(target:orderdeps()) do
                    m = _get_module_from_mapper(_get_module_mapper(dep), required)
                    if m then
                        break
                    end
                end
                if m then
                    _add_module_to_mapper(mapper_file, m[1], m[2])
                    break
                end
            end
            local flags = {"-x", "c++", "-c", path(cppfile), "-o", path(objectfile)}
            batchcmds:show_progress(opt.progress, "${color.build.object}compiling.module.$(mode) %s", name or cppfile)
            batchcmds:mkdir(path.directory(objectfile))
            _batchcmds_compile(batchcmds, target, flags)
            batchcmds:add_depfiles(cppfile)
            target:add("objectfiles", objectfile)
            if provide then
                _add_module_to_mapper(mapper_file, name, path.absolute(provide.bmi, projectdir))
            end
            depmtime = math.max(depmtime, os.mtime(provide and provide.bmi or objectfile))
        end
    end
    batchcmds:set_depmtime(depmtime)
end

-- not supported atm
function get_stdmodules(target)
    local modules = {}
    return modules
end

function get_bmi_extension()
    return ".gcm"
end

function get_modulesflag(target)
    local modulesflag = _g.modulesflag
    if modulesflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fmodules-ts", "cxxflags", {flagskey = "gcc_modules_ts"}) then
            modulesflag = "-fmodules-ts"
        end
        assert(modulesflag, "compiler(gcc): does not support c++ module!")
        _g.modulesflag = modulesflag or false
    end
    return modulesflag or nil
end

function get_modulemapperflag(target)
    local modulemapperflag = _g.modulemapperflag
    if modulemapperflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fmodule-mapper=" .. os.tmpfile(), "cxxflags", {flagskey = "gcc_module_mapper"}) then
            modulemapperflag = "-fmodule-mapper="
        end
        assert(modulemapperflag, "compiler(gcc): does not support c++ module!")
        _g.modulemapperflag = modulemapperflag or false
    end
    return modulemapperflag or nil
end

function get_depflag(target, format)
    local depflag = _g.depflag
    if depflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fdep-format=" .. format, "cxxflags", {flagskey = "gcc_dep_format"}) then
            depflag = "-fdep-format=" .. format
        end
        _g.depflag = depflag or false
    end
    return depflag or nil
end

function get_depfileflag(target)
    local depfileflag = _g.depfileflag
    if depfileflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fdep-file=" .. os.tmpfile(), "cxxflags", {flagskey = "gcc_dep_file",
         on_check = function (ok, errors)
             if errors:find("cc1plus: error: to generate dependencies") then
                ok = true
             end
             return ok, errors
        end}) then
            depfileflag = "-fdep-file="
        end
        _g.depfileflag = depfileflag or false
    end
    return depfileflag or nil
end

function get_depoutputflag(target)
    local depoutputflag = _g.depoutputflag
    if depoutputflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fdep-output=" .. os.tmpfile() .. ".o", "cxxflags", {flagskey = "gcc_dep_output",
         on_check = function (ok, errors)
             if errors:find("cc1plus: error: to generate dependencies") then
                ok = true
             end
             return ok, errors
        end}) then
            depoutputflag = "-fdep-output="
        end
        _g.depoutputflag = depoutputflag or false
    end
    return depoutputflag or nil
end

function get_cppversionflag(target)
    local cppversionflag = _g.cppversionflag
    if cppversionflag == nil then
        local compinst = target:compiler("cxx")
        local flags = compinst:compflags({target = target})
        cppversionflag = table.find_if(flags, function(v) string.startswith(v, "-std=c++") end) or "-std=c++20"
        _g.cppversionflag = cppversionflag
    end
    return cppversionflag or nil
end
