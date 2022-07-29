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
import("core.base.json")
import("core.project.config")
import("private.action.build.object", {alias = "objectbuilder"})

local default_flags = {"-std=c++20"}

function get_module_mapper()
    local mapper_file = path.join(config.buildir(), "mapper.txt")
    if not os.isfile(mapper_file) then
        io.writefile(mapper_file, "")
    end

    return mapper_file
end

function add_module_to_mapper(file, module, bmi)
    for line in io.lines(file) do
        if line:startswith(module .. " ") then
            return false
        end
    end

    local f = io.open(file, "a")
    f:printf("%s %s\n", module, bmi)
    f:close()

    return true
end

-- load parent target with modules files
function load_parent(target, opt)
    local cachedir = path.join(target:autogendir(), "rules", "modules", "cache")
    target:add("cxxflags", "-fmodules-ts")
    target:add("cxxflags", "-fno-module-lazy")
    -- target:add("cxxflags", "-flang-info-include-translate")
    -- target:add("cxxflags", "-flang-info-include-translate-not")
    -- target:add("cxxflags", "-flang-info-module-cmi")
    if os.isfile(get_module_mapper()) then
        os.rm(get_module_mapper())
    end
    target:add("cxxflags", "-fmodule-mapper=" .. get_module_mapper(), {force = true, expand = false})

    for _, dep in ipairs(target:orderdeps()) do
        cachedir = path.join(dep:autogendir(), "rules", "modules", "cache")
        dep:add("cxxflags", "-fmodules-ts")
        dep:add("cxxflags", "-fno-module-lazy")
        -- dep:add("cxxflags", "-flang-info-include-translate")
        -- dep:add("cxxflags", "-flang-info-include-translate-not")
        -- dep:add("cxxflags", "-flang-info-module-cmi")
        dep:add("cxxflags", "-fmodule-mapper=" .. get_module_mapper(), {force = true, expand = false})
    end
end

-- check C++20 module support
function check_module_support(target)
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("-fmodules-ts") then
        modulesflag = "-fmodules-ts"
    end
    assert(modulesflag, "compiler(gcc): does not support c++ module!")

    if compinst:has_flags("-fdep-format=trtbd") then
        target:data_set("cxx.has_p1689r4", true)
    end
end

function generate_dependencies(target, sourcebatch, opt)
    local common = import("common")
    local cachedir = common.get_cache_dir(target)

    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do 
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function()
            vprint("generating.cxx.moduledeps %s", sourcefile)

            local outdir = path.translate(path.join(cachedir, path.directory(path.relative(target:scriptdir(), sourcefile))))
            if not os.isdir(outdir) then
                os.mkdir(outdir)
            end

            local jsonfile = path.translate(path.join(outdir, path.filename(sourcefile) .. ".json"))

            local dependinfo = common.fallback_generate_dependencies(target, jsonfile, sourcefile)
            local jsondata = json.encode(dependinfo)

            io.writefile(jsonfile, jsondata)

            return { moduleinfo = jsondata }
        end, {dependfile = dependfile, files = {sourcefile}})
    end
end

-- generate dependency files
--[[
function generate_dependencies(target, sourcebatch, opt)
    local compinst = target:compiler("cxx")

    local common = import("common")
    local cachedir = common.get_cache_dir(target)
    local common_args = {"-E", "-fmodules-ts", "-x", "c++"}

    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do 
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function()
            vprint("generating.cxx.moduledeps %s", sourcefile)

            local outdir = path.translate(path.join(cachedir, path.directory(path.relative(target:scriptdir(), file))))
            local jsonfile = path.translate(path.join(outdir, path.filename(sourcefile) .. ".json"))
            local ifile = path.translate(path.join(outdir, path.filename(sourcefile) .. ".i"))
            local dfile = path.translate(path.join(outdir, path.filename(sourcefile) .. ".d"))

            local args = {sourcefile, "-MD", "-MT", jsonfile, "-MF", dfile, "-fdep-file=" .. jsonfile, "-fdep-format=trtbd", "-fdep-output=" .. target:objectfile(sourcefile), "-o", ifile}
        
            os.vrunv(compinst:program(), table.join(compinst:compflags({target = target}) or default_flags, common_args, args), {envs = vcvars})

            local dependinfo = io.readfile(jsonfile)

            return { moduleinfo = dependinfo }
        end, {dependfile = dependfile, files = {sourcefile}})
    end
end
]]--

-- generate target header units
function generate_headerunits(target, batchcmds, sourcebatch, opt)
    local common = import("common")

    local compinst = target:compiler("cxx")

    local cachedir = common.get_cache_dir(target)
    local stlcachedir = common.get_stlcache_dir(target)

    local mapper_file = get_module_mapper()

    -- build headerunits
    local objectfiles = {}
    for _, headerunit in ipairs(sourcebatch) do
        if not headerunit.stl then
            local file = path.relative(headerunit.path, target:scriptdir())

            local objectfile = target:objectfile(file)

            local outdir = path.join(cachedir, "include", path.directory(headerunit.name))
            if not os.isdir(outdir) then
                os.mkdir(outdir)
            end

            local bmifilename = path.basename(objectfile) .. ".gcm"

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
                batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}) or default_flags, args))

                batchcmds:add_depfiles(headerunit.path)
                batchcmds:set_depmtime(os.mtime(bmifile))
                batchcmds:set_depcache(target:dependfile(bmifile))
            end
        else
            local bmifile = path.join(stlcachedir, headerunit.name .. ".gcm")

            if add_module_to_mapper(mapper_file, headerunit.path, path.absolute(bmifile, project.directory())) then
                if not os.isfile(bmifile) then
                    local args = { "-c", "-x", "c++-system-header", headerunit.name }

                    batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
                    batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}) or default_flags, args))

                    batchcmds:set_depmtime(os.mtime(bmifile))
                    batchcmds:set_depcache(target:dependfile(bmifile))
                end
            end
        end

    end
end

-- build module files
function build_modules(target, batchcmds, objectfiles, modules, opt)
    local cachedir = common.get_cache_dir(target)
    
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

            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}) or default_flags, common_args, args))

            batchcmds:set_depmtime(os.mtime(objectfile))
            batchcmds:set_depcache(target:dependfile(objectfile))

            target:add("objectfiles", objectfile)
        end
    end
end

