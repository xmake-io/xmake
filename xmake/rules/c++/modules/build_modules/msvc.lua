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
-- @file        msvc.lua
--

-- imports
import("core.tool.compiler")
import("core.project.depend")
import("private.action.build.object", {alias = "objectbuilder"})

local default_flags = {"/EHsc", "/nologo", "/std:c++20", "/experimental:module"}

-- load parent target with modules files
function load_parent(target, opt)
    local common = import("common")
    -- get modules flag
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})

    -- add module flags
    local cachedir = common.get_cache_dir(target)
    local stlcachedir = common.get_stlcache_dir(target)

    target:add("cxxflags", {"/ifcSearchDir", cachedir, "/ifcSearchDir", stlcachedir}, {force = true, expand = false})
    for _, dep in ipairs(target:orderdeps()) do
        cachedir = path.join(dep:autogendir(), "rules", "modules", "cache")
        target:add("cxxflags", {"/ifcSearchDir", cachedir}, {force = true, expand = false})
    end

    for _, toolchain_inst in ipairs(target:toolchains()) do
        if toolchain_inst:name() == "msvc" then
            local vcvars = toolchain_inst:config("vcvars")
            if vcvars.VCInstallDir and vcvars.VCToolsVersion then
                local stdifcdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "ifc", target:is_arch("x64") and "x64" or "x86")
                if os.isdir(stdifcdir) then
                    target:add("cxxflags", {"/stdIfcDir", winos.short_path(stdifcdir)}, {force = true, expand = false})
                end
            end
            break
        end
    end
end

-- check C++20 module support
function check_module_support(target)
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("/experimental:module", "cxxflags") then
        modulesflag = "/experimental:module"
    end
    assert(modulesflag, "compiler(msvc): does not support c++ module!")

    -- get output flag
    local outputflag
    if compinst:has_flags("/ifcOutput", "cxxflags")  then
        outputflag = "/ifcOutput"
    end
    assert(outputflag, "compiler(msvc): does not support c++ module!")

    -- get interface flag
    local interfaceflag
    if compinst:has_flags("/interface", "cxxflags") then
        interfaceflag = "/interface"
    end
    assert(interfaceflag, "compiler(msvc): does not support c++ module!")

    -- get reference flag
    local referenceflag
    if compinst:has_flags("/reference", "cxxflags") then
        referenceflag = "/reference"
    end
    assert(referenceflag, "compiler(msvc): does not support c++ module!")

    -- get stdifcdir flag
    local stdifcdirflag
    if compinst:has_flags("/stdIfcDir", "cxxflags") then
        stdifcdirflag = "/stdIfcDir"
    end
    assert(stdifcdirflag, "compiler(msvc): does not support c++ module!")
end

-- patch sourcebatch
function patch_sourcebatch(target, sourcebatch, opt)
    local common = import("common")
    local cachedir = common.get_cache_dir(target)

    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}

    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do 
        local objectfile = target:objectfile(sourcefile)
        local dependfile = target:dependfile(objectfile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, dependfile)
    end

end

-- generate dependency files
function generate_dependencies(target, sourcebatch, opt)
    local common = import("common")
    local cachedir = common.get_cache_dir(target)
    local compinst = compiler.load("cxx", {target = target})
    local common_args = {"/TP", "/scanDependencies"}

    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do 
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function()
            vprint("generating.cxx.moduledeps %s", sourcefile)

            local outdir = path.join(cachedir, path.directory(path.relative(target:scriptdir(), file)))
            local jsonfile = path.join(outdir, path.filename(sourcefile) .. ".json")

            local args = {jsonfile, sourcefile, "/Fo" .. target:objectfile(sourcefile)}

            os.vrunv(compinst:program(), table.join(compinst:compflags({target = target}) or default_flags, common_args, args))

            local dependinfo = io.readfile(jsonfile)

            return { moduleinfo = dependinfo }
        end, {dependfile = dependfile, files = {sourcefile}})
    end
end 

-- generate target header units
function generate_headerunits(target, batchcmds, sourcebatch, opt)
    local common = import("common")
    local compinst = compiler.load("cxx", {target = target})

    local cachedir = common.get_cache_dir(target)
    local stlcachedir = common.get_stlcache_dir(target)

    -- build headerunits
    local common_args = {"/TP", "/exportHeader", "/c"}
    local objectfiles = {}
    for _, headerunit in ipairs(sourcebatch) do
        if not headerunit.stl then
            local file = path.relative(headerunit.path, target:scriptdir())
            local outdir = path.join(cachedir, path.directory(file))
            if not os.isdir(outdir) then
                os.mkdir(outdir)
            end

            local bmifilename = path.filename(file) .. ".ifc"

            local bmifile = (outdir and path.join(outdir, bmifilename) or bmifilename)
            local objectfile = target:objectfile(file)
            if not os.isdir(path.directory(objectfile)) then
                os.mkdir(path.directory(objectfile))
            end

            local args = {"/headerName" .. headerunit.type, headerunit.path, "/ifcOutput", outdir, "/Fo" .. objectfile}
            batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}) or default_flags, common_args, args))

            batchcmds:add_depfiles(headerunit.path)
            batchcmds:set_depmtime(os.mtime(bmifile))
            batchcmds:set_depcache(target:dependfile(bmifile))
            batchcmds:set_depmtime(os.mtime(objectfile))
            batchcmds:set_depcache(target:dependfile(objectfile))

            local flag = {"/headerUnit" .. headerunit.type, headerunit.name .. "=" .. path.relative(bmifile, cachedir)}
            target:add("cxxflags", flag, {force = true, expand = false})
            target:data_add("cxx.modules.flags", "/headerUnit" .. headerunit.type)
            target:data_add("cxx.modules.flags", path.filename(file) .. "=" .. path.relative(bmifile, cachedir))
            target:add("objectfiles", objectfile)
        else
            local bmifile = path.join(stlcachedir, headerunit.name .. ".ifc")

            local args = {"/exportHeader", "/headerName:angle", headerunit.name, "/ifcOutput", stlcachedir}
            batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}) or default_flags, args))

            batchcmds:set_depmtime(os.mtime(bmifile))
            batchcmds:set_depcache(target:dependfile(bmifile))

            local flag = {"/headerUnit:angle", headerunit.name .. "=" .. headerunit.name .. ".ifc"}
            target:add("cxxflags", flag, {force = true, expand = false})
            target:data_add("cxx.modules.flags", "/headerUnit" .. headerunit.type)
            target:data_add("cxx.modules.flags", headerunit.name .. "=" .. headerunit.name .. ".ifc")
        end
    end
end

-- build module files
-- TODO detect dependencies, and build in the right order
function build_modules(target, batchcmds, objectfiles, modules, opt)
    local compinst = compiler.load("cxx", {target = target})
    local cachedir = common.get_cache_dir(target)
    
    -- append deps modules
    for _, dep in ipairs(target:orderdeps()) do
        target:add("cxxflags", dep:data("cxx.modules.flags"), {force = true, expand = false})
    end

    -- compile module files to bmi files
    local common_args = {"/TP"}
    for _, objectfile in ipairs(objectfiles) do
        local m = modules[objectfile]

        if m then
            if not os.isdir(path.directory(objectfile)) then
                os.mkdir(path.directory(objectfile))
            end

            local args = {"/c", "/Fo" .. objectfile}

            local flag = {}
            for name, provide in pairs(m.provides) do
                batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.module.bmi %s", name)

                local bmifile = provide.bmi
                 
                table.join2(args, {"/interface", "/ifcOutput", bmifile, provide.sourcefile})

                batchcmds:set_depmtime(os.mtime(bmifile))
                batchcmds:set_depcache(target:dependfile(bmifile))

                table.join2(flag, {"/reference", name .. "=" .. path.filename(bmifile)})
            end  

            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}) or default_flags, common_args, args))

            batchcmds:add_depfiles(m.sourcefile)
            batchcmds:set_depmtime(os.mtime(objectfile))
            batchcmds:set_depcache(target:dependfile(objectfile))

            target:add("cxxflags", flag, {force = true, expand = false})
            for _, f in ipairs(flag) do
                target:data_add("cxx.modules.flags", f)
            end
            target:add("objectfiles", objectfile)
        end
    end
end
