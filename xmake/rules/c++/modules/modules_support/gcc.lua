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
function _get_module_mapper()
    local mapper_file = path.join(config.buildir(), "mapper.txt")
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

-- load module support for the current target
function load(target)
    local modulesflag = get_modulesflag(target)
    local modulemapperflag = get_modulemapperflag(target)
    target:add("cxxflags", modulesflag)
    if os.isfile(_get_module_mapper()) then
        os.rm(_get_module_mapper())
    end
    target:add("cxxflags", modulemapperflag .. _get_module_mapper(), {force = true, expand = false})
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
    progress.show(opt.progress, "${color.build.object}generating.cxx.module.bmi %s", opt.name)
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
    local trtbdflag = get_trtbdflag(target)
    local depfileflag = get_depfileflag(target)
    local depoutputflag = get_depoutputflag(target)
    local changed = false
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

            local jsonfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".json"))
            if trtbdflag and depfileflag and depoutputflag then
                local ifile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".i"))
                local dfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".d"))
                local args = {sourcefile, "-MD", "-MT", jsonfile, "-MF", dfile, depfileflag .. jsonfile, trtbdflag, depoutputfile .. target:objectfile(sourcefile), "-o", ifile}
                os.vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_args, args), {envs = vcvars})
            else
                common.fallback_generate_dependencies(target, jsonfile, sourcefile, function(file)
                    local compinst = target:compiler("cxx")
                    local defines = {}
                    for _, define in ipairs(target:get("defines")) do
                        table.insert(defines, "-D" .. define)
                    end
                    local ifile = path.translate(path.join(outputdir, path.filename(file) .. ".i"))
                    os.vrunv(compinst:program(), table.join(defines, {get_cppversionflag(target), "-E", "-x", "c++", file,  "-o", ifile}))
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
    local mapper_file = _get_module_mapper()
    local stlcachedir = common.stlmodules_cachedir(target)
    local modulemapperflag = get_modulemapperflag(target)

    -- build headerunits
    local projectdir = os.projectdir()
    for _, headerunit in ipairs(headerunits) do
        local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_extension())
        if not os.isfile(bmifile) then
            batchjobs:addjob(headerunit.name, function (index, total)
                depend.on_changed(function()
                    progress.show((index * 100) / total, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
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
    local compinst = target:compiler("cxx")
    local mapper_file = _get_module_mapper()
    local stlcachedir = common.stlmodules_cachedir(target)

    -- build headerunits
    local projectdir = os.projectdir()
    local depmtime = 0
    for _, headerunit in ipairs(headerunits) do
        local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_extension())
        if not os.isfile(bmifile) then
            local args = {"-c", "-x", "c++-system-header", headerunit.name}
            batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))
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
    local mapper_file = _get_module_mapper()
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
                progress.show((index * 100) / total, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
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
    local compinst = target:compiler("cxx")
    local mapper_file = _get_module_mapper()
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

        local args = {"-c"}
        local headerunit_path
        if headerunit.type == ":quote" then
            table.join2(args, {"-I", path(path.relative(headerunit.path, projectdir)):directory(), "-x", "c++-user-header", headerunit.name})
            headerunit_path = path.join(".", path.relative(headerunit.path, projectdir))
        elseif headerunit.type == ":angle" then
            table.join2(args, {"-x", "c++-system-header", headerunit.name})
            -- if path is relative then its a subtarget path
            headerunit_path = path.is_absolute(headerunit.path) and headerunit.path or path.join(".", headerunit.path)
        end

        batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
        batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))
        batchcmds:add_depfiles(headerunit.path)

        _add_module_to_mapper(mapper_file, headerunit_path, path.absolute(bmifile, projectdir))
        depmtime = math.max(depmtime, os.mtime(bmifile))
    end
    batchcmds:set_depmtime(depmtime)
end

-- build module files for batchjobs
function build_modules_for_batchjobs(target, batchjobs, objectfiles, modules, opt)
    local mapper_file = _get_module_mapper()
    local cachedir = common.modules_cachedir(target)

    -- build modules
    local projectdir = os.projectdir()
    local provided_modules = {}
    for _, objectfile in ipairs(objectfiles) do
        local m = modules[objectfile]
        if m and m.provides then
            -- assume there that provides is only one, until we encounter the case
            local length = 0
            local name, provide
            for k, v in pairs(m.provides) do
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
                _build_modulefile(target, provide.sourcefile, {
                    objectfile = objectfile,
                    dependfile = target:dependfile(bmifile),
                    name = name,
                    progress = (index * 100) / total})
            end)
            if m.requires then
                moduleinfo.deps = table.keys(m.requires)
            end
            moduleinfo.name = name
            provided_modules[name] = moduleinfo
            _add_module_to_mapper(mapper_file, name, path.absolute(bmifile, projectdir))
            target:add("objectfiles", objectfile)
        end
    end

    -- build batchjobs for modules
    common.build_batchjobs_for_modules(provided_modules, batchjobs, opt.rootjob)
end

-- build module files for batchcmds
function build_modules_for_batchcmds(target, batchcmds, objectfiles, modules, opt)
    local compinst = target:compiler("cxx")
    local mapper_file = _get_module_mapper()
    local common_args = {"-x", "c++"}
    local cachedir = common.modules_cachedir(target)

    -- build modules
    local projectdir = os.projectdir()
    local depmtime = 0
    for _, objectfile in ipairs(objectfiles) do
        local m = modules[objectfile]
        if m and m.provides then
            -- assume there that provides is only one, until we encounter the case
            local length = 0
            local name, provide
            for k, v in pairs(m.provides) do
                length = length + 1
                name = k
                provide = v
                if length > 1 then
                    raise("multiple provides are not supported now!")
                end
            end

            local bmifile = provide.bmi
            local args = {"-o", path(objectfile), "-c", path(provide.sourcefile)}
            batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.module.bmi %s", name)
            batchcmds:mkdir(path.directory(objectfile))
            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_args, args))
            batchcmds:add_depfiles(provide.sourcefile)

            _add_module_to_mapper(mapper_file, name, path.absolute(bmifile, projectdir))

            target:add("objectfiles", objectfile)
            depmtime = math.max(depmtime, os.mtime(bmifile))
        end
    end
    batchcmds:set_depmtime(depmtime)
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

function get_trtbdflag(target)
    local trtbdflag = _g.trtbdflag
    if trtbdflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fdep-format=trtbd", "cxxflags", {flagskey = "gcc_dep_format"}) then
            trtbdflag = "-fdep-format=trtbd"
        end
        _g.trtbdflag = trtbdflag or false
    end
    return trtbdflag or nil
end

function get_depfileflag(target)
    local depfileflag = _g.depfileflag
    if depfileflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fdep-file=" .. os.tmpfile(), "cxxflags", {flagskey = "gcc_dep_file"}) then
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
        if compinst:has_flags("-fdep-output=" .. os.tmpfile() .. ".o", "cxxflags", {flagskey = "gcc_dep_output"}) then
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