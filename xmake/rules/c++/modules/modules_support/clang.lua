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
import("core.tool.compiler")
import("core.project.project")
import("core.project.depend")
import("core.project.config")
import("utils.progress")
import("private.action.build.object", {alias = "objectbuilder"})

modulesflag = nil
modulestsflag = nil
implicitmodules = nil
implicitmodulemapsflag = nil
prebuiltmodulepathflag = nil

function get_bmi_ext()
    return ".pcm"
end

-- load parent target with modules files
function load_parent(target, opt)
    local common = import("common")
    local cachedir = common.get_cache_dir(target)
    local stlcachedir = common.get_stlcache_dir(target)

    -- add module flags
    target:add("cxxflags", modulesflag or modulestsflag)

    -- add the module cache directory
    target:add("cxxflags", implicitmodulesflag, {force = true})
    target:add("cxxflags", implicitmodulemapsflag, {force = true})

    target:add("cxxflags", prebuiltmodulepathflag .. cachedir, prebuiltmodulepathflag .. stlcachedir, {force = true})

    for _, dep in ipairs(target:orderdeps()) do
        cachedir = common.get_cache_dir(dep)
        target:add("cxxflags", prebuiltmodulepathflag .. cachedir, prebuiltmodulepathflag .. stlcachedir, {force = true})
        target:add("cxxflags", prebuiltmodulepathflag .. cachedir, {force = true})
    end
end

-- check C++20 module support
function check_module_support(target)
    local compinst = compiler.load("cxx", {target = target})

    if compinst:has_flags("-fmodules", "cxxflags", {flagskey = "clang_modules"}) then
        modulesflag = "-fmodules"
    end

    if compinst:has_flags("-fmodules-ts", "cxxflags", {flagskey = "clang_modules_ts"}) then
        modulestsflag = "-fmodules-ts"
    end
    assert(modulesflag or modulestsflag, "compiler(clang): does not support c++ module!")

    if compinst:has_flags((modulesflag or modulestsflag) .. " -fimplicit-modules", "cxxflags", {flagskey = "clang_implicit_modules"}) then
        implicitmodulesflag = "-fimplicit-modules"
    end
    assert(implicitmodulesflag, "compiler(clang): does not support c++ module!")

    if compinst:has_flags((modulesflag or modulestsflag) .. " -fimplicit-module-maps" .. os.tmpdir(), "cxxflags", {flagskey = "clang_implicit_module_path"}) then
        implicitmodulemapsflag = "-fimplicit-module-maps"
    end
    assert(implicitmodulemapsflag, "compiler(clang): does not support c++ module!")

    if compinst:has_flags((modulesflag or modulestsflag) .. " -fprebuilt-module-path=" .. os.tmpdir(), "cxxflags", {flagskey = "clang_prebuild_module_path"}) then
        prebuiltmodulepathflag = "-fprebuilt-module-path="
    end
    assert(prebuiltmodulepathflag, "compiler(clang): does not support c++ module!")

    if compinst:has_flags((modulesflag or modulestsflag) .. " -fmodules-cache-path=" .. os.tmpdir(), "cxxflags", {flagskey = "clang_modules_cache_path"}) then
        modulecachepathflag = "-fmodules-cache-path="
    end
    assert(modulecachepathflag, "compiler(clang): does not support c++ module!")

    if compinst:has_flags((modulesflag or modulestsflag) .. " -emit-module", "cxxflags", {flagskey = "clang_emit_module"}) then
        emitmoduleflag = " -emit-module"
    end
    assert(emitmoduleflag, "compiler(clang): does not support c++ module!")

    if compinst:has_flags((modulesflag or modulestsflag) .. " -fmodule-file=" .. os.tmpfile() .. get_bmi_ext(), "cxxflags", {flagskey = "clang_module_file"}) then
        modulefileflag = "-fmodule-file="
    end
    assert(modulefileflag, "compiler(clang): does not support c++ module!")

    if compinst:has_flags((modulesflag or modulestsflag) .. " -emit-module-interface", "cxxflags", {flagskey = "clang_emit_module_interface"}) then
        emitmoduleinterfaceflag = "-emit-module-interface"
    end
    assert(emitmoduleinterfaceflag, "compiler(clang): does not support c++ module!")
end

function toolchain_include_directories(target)
    if is_plat("linux") then
        return { "/usr/include/**", "/usr/local/include/**" }
    end

    return {}
end

function generate_dependencies(target, sourcebatch, opt)
    local common = import("common")
    local cachedir = common.get_cache_dir(target)

    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do 
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function()
			progress.show(opt.progress, "${color.build.object}generating.cxx.module.deps %s", sourcefile)

            local outdir = path.translate(path.join(cachedir, path.directory(path.relative(sourcefile, target:scriptdir()))))
            if not os.isdir(outdir) then
                os.mkdir(outdir)
            end

            local jsonfile = path.translate(path.join(outdir, path.filename(sourcefile) .. ".json"))

            -- no support of p1689 atm
            common.fallback_generate_dependencies(target, jsonfile, sourcefile)

            local dependinfo = io.readfile(jsonfile)

            return { moduleinfo = dependinfo }
        end, {dependfile = dependfile, files = {sourcefile}})
    end
end

-- generate target header units
function generate_headerunits(target, batchcmds, sourcebatch, opt)
    local common = import("common")

    local compinst = target:compiler("cxx")

    local cachedir = common.get_cache_dir(target)
    local stlcachedir = common.get_stlcache_dir(target)

    -- build headerunits
    local objectfiles = {}
    local public_flags = {}
    local private_flags = {}
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

            local bmifilename = path.basename(objectfile) .. get_bmi_ext()

            local bmifile = (outdir and path.join(outdir, bmifilename) or bmifilename)
            if not os.isdir(path.directory(objectfile)) then
                os.mkdir(path.directory(objectfile))
            end

            local args = { modulecachepathflag .. cachedir, emitmoduleflag, "-c", "-o", bmifile }
            if headerunit.type == ":quote" then
                table.join2(args, {  "-I", path.directory(headerunit.path), "-x", "c++-user-header", headerunit.path })
            elseif headerunit.type == ":angle" then
                table.join2(args, { "-x", "c++-system-header", headerunit.name })
            end

            batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))

            batchcmds:add_depfiles(headerunit.path)
            batchcmds:set_depmtime(os.mtime(bmifile))
            batchcmds:set_depcache(target:dependfile(bmifile))

            table.append(public_flags, modulefileflag .. bmifile)
        else
            local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_ext())

            if not os.isfile(bmifile) then
                local args = { modulecachepathflag .. stlcachedir, "-c", "-o", bmifile, "-x", "c++-system-header", headerunit.path }

                batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
                batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args))

            end

            batchcmds:set_depmtime(os.mtime(bmifile))
            batchcmds:set_depcache(target:dependfile(bmifile))

            table.append(private_flags, modulefileflag .. bmifile)
        end
    end

    return public_flags, private_flags
end

-- build module files
function build_modules(target, batchcmds, objectfiles, modules, opt)
    local cachedir = common.get_cache_dir(target)
    
    local compinst = target:compiler("cxx")

    -- append deps modules
    local flags = {}
    for _, dep in ipairs(target:orderdeps()) do
        table.join2(flags, dep:data("cxx.modules.flags"))
    end
    flags = table.unique(flags)
    target:add("cxxflags", flags, {force = true, expand = false})

    local common_args = { modulecachepathflag .. cachedir }
    for _, objectfile in ipairs(objectfiles) do
        local m = modules[objectfile]

        if m then
            if not os.isdir(path.directory(objectfile)) then
                os.mkdir(path.directory(objectfile))
            end

            local args = { emitmoduleinterfaceflag }
            local flag = {}
            local bmifiles = {}
            for name, provide in pairs(m.provides) do
                batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.module.bmi %s", name)

                local bmifile = provide.bmi
                table.join2(args, { "-c", "-x", "c++-module", "--precompile", provide.sourcefile, "-o", bmifile })
                table.join2(bmifiles, bmifile)

                batchcmds:add_depfiles(provide.sourcefile)
                batchcmds:set_depmtime(os.mtime(bmifile))
                batchcmds:set_depcache(target:dependfile(bmifile))

                table.join2(flag, { modulefileflag .. bmifile })
            end  

            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_args, args))
            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_args, bmifiles, {"-c", "-o", objectfile}))

            batchcmds:set_depmtime(os.mtime(objectfile))
            batchcmds:set_depcache(target:dependfile(objectfile))

            target:add("cxxflags", flag, {public = true, force = true})
            target:add("objectfiles", objectfile)
            for _, f in ipairs(flag) do
                target:data_add("cxx.modules.flags", f)
            end
        end
    end
end
