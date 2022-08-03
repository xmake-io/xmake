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
import("core.tool.compiler")
import("core.project.project")
import("core.project.depend")
import("core.project.config")
import("utils.progress")
import("private.action.build.object", {alias = "objectbuilder"})
import("common")

-- get and create the path of module mapper
function get_module_mapper()
    local mapper_file = path.join(config.buildir(), "mapper.txt")
    if not os.isfile(mapper_file) then
        io.writefile(mapper_file, "")
    end

    return mapper_file
end

-- add a module or header unit into the mapper
function add_module_to_mapper(file, module, bmi)
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

-- load parent target with modules files
function load_parent(target, opt)
end

-- check C++20 module support
function check_module_support(target)
    local compinst = compiler.load("cxx", {target = target})

    local modulesflag = get_modulesflag(target)
    local modulemapperflag = get_modulemapperflag(target)

    target:add("cxxflags", modulesflag)

    if os.isfile(get_module_mapper()) then
        os.rm(get_module_mapper())
    end
    target:add("cxxflags", modulemapperflag .. get_module_mapper(), {force = true, expand = false})
end

-- provide toolchain include dir for stl headerunit when p1689 is not supported
function toolchain_include_directories(target)
    local includedirs = _g.includedirs
    if includedirs == nil then
        includedirs = {}

        local gcc, toolname = target:tool("cc")
        assert(toolname == "gcc")

        local _, result = try {function () return os.iorunv(gcc, {"-E", "-Wp,-v", "-xc", os.nuldev()}) end}
        if result then
            for _, line in ipairs(result:split("\n", {plain = true})) do
                line = line:trim()
                if os.isdir(line) then
                    table.append(includedirs, line)
                    break
                elseif line:startswith("End") then
                    break
                end
            end
        end
        _g.includedirs = includedirs or {}
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

    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function()
            progress.show(opt.progress, "${color.build.object}generating.cxx.module.deps %s", sourcefile)

            local outdir = path.translate(path.join(cachedir, path.directory(path.relative(sourcefile, target:scriptdir()))))
            if not os.isdir(outdir) then
                os.mkdir(outdir)
            end

            local jsonfile = path.translate(path.join(outdir, path.filename(sourcefile) .. ".json"))

            if trtbdflag and depfileflag and depoutputflag then
                local ifile = path.translate(path.join(outdir, path.filename(sourcefile) .. ".i"))
                local dfile = path.translate(path.join(outdir, path.filename(sourcefile) .. ".d"))

                local args = {sourcefile, "-MD", "-MT", jsonfile, "-MF", dfile, depfileflag .. jsonfile, trtbdflag, depoutputfile .. target:objectfile(sourcefile), "-o", ifile}

                os.vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_args, args), {envs = vcvars})
            else
                common.fallback_generate_dependencies(target, jsonfile, sourcefile)
            end

            local dependinfo = io.readfile(jsonfile)

            return { moduleinfo = dependinfo }
        end, {dependfile = dependfile, files = {sourcefile}})
    end
end

-- generate target header units
function generate_headerunits(target, batchcmds, sourcebatch, opt)
    local compinst = target:compiler("cxx")

    local cachedir = common.modules_cachedir(target)
    local stlcachedir = common.stlmodules_cachedir(target)

    local mapper_file = get_module_mapper()

    -- build headerunits
    local objectfiles = {}
    for _, headerunit in ipairs(sourcebatch) do
        if not headerunit.stl then
            local file = path.relative(headerunit.path, target:scriptdir())

            local objectfile = target:objectfile(file)

            local outdir
            if headerunit.type == ":quote" then
                outdir = path.join(cachedir, path.directory(path.relative(headerunit.path, project.directory())))
            else
                outdir = path.join(cachedir, path.directory(headerunit.path))
            end

            if not os.isdir(outdir) then
                os.mkdir(outdir)
            end

            local bmifilename = path.basename(objectfile) .. bmi_extension()

            local bmifile = (outdir and path.join(outdir, bmifilename) or bmifilename)
            if not os.isdir(path.directory(objectfile)) then
                os.mkdir(path.directory(objectfile))
            end

            if add_module_to_mapper(mapper_file, headerunit.path, path.absolute(bmifile, project.directory())) then
                local args = { "-c" }
                if headerunit.type == ":quote" then
                    table.join2(args, { "-I", path.directory(headerunit.path), "-x", "c++-user-header", headerunit.name })
                    add_module_to_mapper(mapper_file, path.join(".", path.relative(headerunit.path, project.directory())), path.absolute(bmifile, project.directory()))
                elseif headerunit.type == ":angle" then
                    table.join2(args, { "-x", "c++-system-header", headerunit.name })
                    add_module_to_mapper(mapper_file, headerunit.name, path.absolute(bmifile, project.directory()))
                end

                batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
                batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))

                batchcmds:add_depfiles(headerunit.path)
                batchcmds:set_depmtime(os.mtime(bmifile))
                batchcmds:set_depcache(target:dependfile(bmifile))
            end
        else
            local bmifile = path.join(stlcachedir, headerunit.name .. bmi_extension())

            if add_module_to_mapper(mapper_file, headerunit.path, path.absolute(bmifile, project.directory())) then
                if not os.isfile(bmifile) then
                    local args = { "-c", "-x", "c++-system-header", headerunit.name }

                    batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
                    batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))

                    batchcmds:set_depmtime(os.mtime(bmifile))
                    batchcmds:set_depcache(target:dependfile(bmifile))
                end
            end
        end
    end
end

-- build module files
function build_modules(target, batchcmds, objectfiles, modules, opt)
    local cachedir = common.modules_cachedir(target)

    local compinst = target:compiler("cxx")

    local mapper_file = get_module_mapper()
    local common_args = { "-x", "c++" }
    for _, objectfile in ipairs(objectfiles) do
        local m = modules[objectfile]

        if m then
            if not os.isdir(path.directory(objectfile)) then
                os.mkdir(path.directory(objectfile))
            end

            local args = { "-o", objectfile }
            for name, provide in pairs(m.provides) do
                batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.module.bmi %s", name)

                local bmifile = provide.bmi
                if add_module_to_mapper(mapper_file, name, path.absolute(bmifile, project.directory())) then
                    table.join2(args, { "-c", provide.sourcefile })

                    batchcmds:add_depfiles(provide.sourcefile)
                    batchcmds:set_depmtime(os.mtime(bmifile))
                    batchcmds:set_depcache(target:dependfile(bmifile))
                end
            end

            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_args, args))

            batchcmds:set_depmtime(os.mtime(objectfile))
            batchcmds:set_depcache(target:dependfile(objectfile))

            target:add("objectfiles", objectfile)
        end
    end
end

function bmi_extension()
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
    return modulesflag
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
    return modulemapperflag
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
    return trtbdflag
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
    return depfileflag
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
    return depoutputflag
end
