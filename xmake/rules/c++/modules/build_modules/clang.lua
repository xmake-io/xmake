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
import("core.base.json")
import("core.project.config")
import("utils.progress")
import("private.action.build.object", {alias = "objectbuilder"})

local default_flags = { "-std=c++20" }

-- load parent target with modules files
function load_parent(target, opt)
    local common = import("common")
    local cachedir = common.get_cache_dir(target)
    local stlcachedir = common.get_stlcache_dir(target)

    -- add module flags
    target:add("cxxflags", "-fmodules")

    -- add the module cache directory
    target:add("cxxflags", "-fimplicit-modules", "-fimplicit-module-maps", {force = true})
    target:add("cxxflags", "-fprebuilt-module-path=" .. cachedir, "-fprebuilt-module-path=" .. stlcachedir, {force = true})

    for _, dep in ipairs(target:orderdeps()) do
        cachedir = common.get_cache_dir(dep)
        dep:add("cxxflags", "-fmodules")
        dep:add("cxxflags", "-fimplicit-modules", "-fimplicit-module-maps", {force = true})
        target:add("cxxflags", "-fprebuilt-module-path=" .. cachedir, "-fprebuilt-module-path=" .. stlcachedir, {force = true})
        target:add("cxxflags", "-fprebuilt-module-path=" .. cachedir, {force = true})
    end
end

-- check C++20 module support
function check_module_support(target)
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("-fmodules") then
        modulesflag = "-fmodules"
    end
    assert(modulesflag, "compiler(clang): does not support c++ module!")

    target:data_set("cxx.has_p1689r4", false)
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

            if target:data("cxx.has_p1689r4") then
            else -- fallback as clang doesn't support p1689r4
                local dependinfo = common.fallback_generate_dependencies(target, jsonfile, sourcefile)
                local jsondata = json.encode(dependinfo)

                io.writefile(jsonfile, jsondata)
            end

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

            local outdir = path.join(cachedir, "include", path.directory(headerunit.name))
            if not os.isdir(outdir) then
                os.mkdir(outdir)
            end

            local bmifilename = path.basename(objectfile) .. ".pcm"

            local bmifile = (outdir and path.join(outdir, bmifilename) or bmifilename)
            if not os.isdir(path.directory(objectfile)) then
                os.mkdir(path.directory(objectfile))
            end

            local args = { "-fmodules-cache-path=" .. cachedir, "-emit-module", "-c", "-o", bmifile }
            if headerunit.type == ":quote" then
                table.join2(args, {  "-I", path.directory(headerunit.path), "-x", "c++-user-header", headerunit.path })
            elseif headerunit.type == ":angle" then
                table.join2(args, { "-x", "c++-system-header", headerunit.name })
            end

            batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}) or default_flags, args))

            batchcmds:add_depfiles(headerunit.path)
            batchcmds:set_depmtime(os.mtime(bmifile))
            batchcmds:set_depcache(target:dependfile(bmifile))

            table.append(public_flags, "-fmodule-file=" .. bmifile)
        else
            local bmifile = path.join(stlcachedir, headerunit.name .. ".pcm")

            if not os.isfile(bmifile) then
                local args = { "-fmodules-cache-path=" .. stlcachedir, "-c", "-o", bmifile, "-x", "c++-system-header", headerunit.path }

                batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
                batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}) or default_flags, args))

            end

            batchcmds:set_depmtime(os.mtime(bmifile))
            batchcmds:set_depcache(target:dependfile(bmifile))

            table.append(private_flags, "-fmodule-file=" .. bmifile)
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

    local common_args = { "-fmodules-cache-path=" .. cachedir, "-emit-module-interface" }
    for _, objectfile in ipairs(objectfiles) do
        local m = modules[objectfile]

        if m then
            if not os.isdir(path.directory(objectfile)) then
                os.mkdir(path.directory(objectfile))
            end

            local args = { }
            local flag = {}
            for name, provide in pairs(m.provides) do
                batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.module.bmi %s", name)

                local bmifile = provide.bmi
                table.join2(args, { "-c", "-x", "c++-module", "--precompile", provide.sourcefile, "-o", bmifile })

                batchcmds:add_depfiles(provide.sourcefile)
                batchcmds:set_depmtime(os.mtime(bmifile))
                batchcmds:set_depcache(target:dependfile(bmifile))

                table.join2(flag, { "-fmodule-file=" .. bmifile })
            end  

            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}) or default_flags, common_args, args))

            target:add("cxxflags", flag, {public = true, force = true})
            for _, f in ipairs(flag) do
                target:data_add("cxx.modules.flags", f)
            end
        end
    end
end
