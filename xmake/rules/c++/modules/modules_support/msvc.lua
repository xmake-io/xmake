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
import("core.project.project")
import("core.project.depend")
import("utils.progress")
import("private.action.build.object", {alias = "objectbuilder"})

modulesflag = nil
ifcoutputflag = nil
ifcsearchdirflag = nil
interfaceflag = nil
referenceflag = nil
headernameflag = nil
headerunitflag = nil
exportheaderflag = nil
stdifcdirflag = nil
scandependenciesflag = nil
cxxsourcefileflag = "/TP"

function get_bmi_ext()
    return ".ifc"
end

-- load parent target with modules files
function load_parent(target, opt)
    local common = import("common")
    -- get modules flag
    local compinst = target:compiler("cxx")

    -- add module flags
    local cachedir = common.get_cache_dir(target)
    local stlcachedir = common.get_stlcache_dir(target)

    target:add("cxxflags", modulesflag)
    target:add("cxxflags", {ifcsearchdirflag, cachedir}, {force = true, expand = false})
    target:add("cxxflags", {ifcsearchdirflag, stlcachedir}, {force = true, expand = false})

    for _, dep in ipairs(target:orderdeps()) do
        cachedir = common.get_cache_dir(dep)
        target:add("cxxflags", {ifcsearchdirflag, cachedir}, {force = true, expand = false})
    end

    for _, toolchain_inst in ipairs(target:toolchains()) do
        if toolchain_inst:name() == "msvc" then
            local vcvars = toolchain_inst:config("vcvars")
            if vcvars.VCInstallDir and vcvars.VCToolsVersion then
                local stdifcdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "ifc", target:is_arch("x64") and "x64" or "x86")
                if os.isdir(stdifcdir) then
                    target:add("cxxflags", {stdifcdirflag, winos.short_path(stdifcdir)}, {force = true, expand = false})
                end
            end
            break
        end
    end
end

-- check C++20 module support
function check_module_support(target)
    local compinst = target:compiler("cxx")

    if compinst:has_flags("/experimental:module", "cxxflags", {flagskey = "cl_experimental_module"}) then
        modulesflag = "/experimental:module"
    end
    assert(modulesflag, "compiler(msvc): does not support c++ module!")

    -- get ifcoutput flag
    if compinst:has_flags("/ifcOutput", "cxxflags", {flagskey = "cl_ifc_output"})  then
        ifcoutputflag = "/ifcOutput"
    end
    assert(ifcoutputflag, "compiler(msvc): does not support c++ module!")

    -- get ifcsearchdir flag
    if compinst:has_flags("/ifcSearchDir", "cxxflags", {flagskey = "cl_ifc_search_dir"})  then
        ifcsearchdirflag = "/ifcSearchDir"
    end
    assert(ifcsearchdirflag, "compiler(msvc): does not support c++ module!")

    -- get interface flag
    if compinst:has_flags("/interface", "cxxflags", {flagskey = "cl_interface"}) then
        interfaceflag = "/interface"
    end
    assert(interfaceflag, "compiler(msvc): does not support c++ module!")

    -- get reference flag
    if compinst:has_flags("/reference", "cxxflags", {flagskey = "cl_reference"}) then
        referenceflag = "/reference"
    end
    assert(referenceflag, "compiler(msvc): does not support c++ module!")

    -- get headername flag
    if compinst:has_flags("/headerName:quote", "cxxflags", {flagskey = "cl_header_name_quote"}) and
       compinst:has_flags("/headerName:angle", "cxxflags", {flagskey = "cl_header_name_angle"}) then
        headernameflag = "/headerName"
    end
    assert(headernameflag, "compiler(msvc): does not support c++ module!")

    -- get headerunit flag
    if compinst:has_flags("/headerUnit:quote", "cxxflags", {flagskey = "cl_header_unit_quote"}) and 
       compinst:has_flags("/headerUnit:angle", "cxxflags", {flagskey = "cl_header_unit_angle"}) then
        headerunitflag = "/headerUnit"
    end
    assert(headerunitflag, "compiler(msvc): does not support c++ module!")

    -- get exportheader flag
    if compinst:has_flags(modulesflag .. " /exportHeader", "cxxflags", {flagskey = "cl_export_header"}) then
        exportheaderflag = "/exportHeader"
    end
    assert(exportheaderflag, "compiler(msvc): does not support c++ module!")

    -- get stdifcdir flag
    if compinst:has_flags("/stdIfcDir", "cxxflags", {flagskey = "cl_ifc_dir"}) then
        stdifcdirflag = "/stdIfcDir"
    end
    assert(stdifcdirflag, "compiler(msvc): does not support c++ module!")

    -- get scandependencies flag
    local scan_dependencies_jsonfile = os.tmpfile() .. ".json"
    if compinst:has_flags("/scanDependencies " .. scan_dependencies_jsonfile, "cxflags", {flagskey = "cl_scan_dependencies",
        on_check = function (ok, errors)
            if os.isfile(scan_dependencies_jsonfile) then
                ok = true
            end

            if ok and not os.isfile(scan_dependencies_jsonfile) then
                ok = false
            end

            return ok, errors
        end}) then
        scandependenciesflag = "/scanDependencies"
    end
end

-- provide toolchain include dir for stl headerunit when p1689 is not supported
function toolchain_include_directories(target)
    for _, toolchain_inst in ipairs(target:toolchains()) do
        if toolchain_inst:name() == "msvc" then
            local vcvars = toolchain_inst:config("vcvars")
            if vcvars.VCInstallDir and vcvars.VCToolsVersion then
                return { path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "include") }
            end
            break
        end
    end

    assert(false)
end

-- generate dependency files
function generate_dependencies(target, sourcebatch, opt)
    local compinst = target:compiler("cxx")
    local toolchain = target:toolchain("msvc")
    local vcvars = toolchain:config("vcvars")

    local common = import("common")
    local cachedir = common.get_cache_dir(target)
    local common_args = {cxxsourcefileflag, scandependenciesflag}  

    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do 
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function()
            progress.show(opt.progress, "${color.build.object}generating.cxx.module.deps %s", sourcefile)

            local outdir = path.join(cachedir, path.directory(path.relative(sourcefile, target:scriptdir())))
            if not os.isdir(outdir) then
                os.mkdir(outdir)
            end

            local jsonfile = path.join(outdir, path.filename(sourcefile) .. ".json")

            if scandependenciesflag then
                local args = {jsonfile, sourcefile, "/Fo" .. target:objectfile(sourcefile)}
            
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
    local common = import("common")

    local compinst = target:compiler("cxx")
    local toolchain = target:toolchain("msvc")
    local vcvars = toolchain:config("vcvars")

    local cachedir = common.get_cache_dir(target)
    local stlcachedir = common.get_stlcache_dir(target)

    -- build headerunits
    local common_args = {cxxsourcefileflag, exportheaderflag, "/c"}
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
                outdir = path.join(cachedir, path.directory(headerunit.path):sub(3))
            end

            if not os.isdir(outdir) then
                os.mkdir(outdir)
            end

            local bmifilename = path.basename(objectfile) .. get_bmi_ext()

            local bmifile = (outdir and path.join(outdir, bmifilename) or bmifilename)
            if not os.isdir(path.directory(objectfile)) then
                os.mkdir(path.directory(objectfile))
            end

            local args = {headernameflag .. headerunit.type, headerunit.path, ifcoutputflag, outdir, "/Fo" .. objectfile}
            batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_args, args), {envs = vcvars})

            batchcmds:add_depfiles(headerunit.path)
            batchcmds:set_depmtime(os.mtime(bmifile))
            batchcmds:set_depcache(target:dependfile(bmifile))
            batchcmds:set_depmtime(os.mtime(objectfile))
            batchcmds:set_depcache(target:dependfile(objectfile))

            local flag = {headerunitflag .. headerunit.type, headerunit.name .. "=" .. path.relative(bmifile, cachedir)}
            table.join2(public_flags, flag)
            target:add("objectfiles", objectfile)
        else
            local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_ext())
            local args = {exportheaderflag, headernameflag .. ":angle", headerunit.name, ifcoutputflag, stlcachedir}
            batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", headerunit.name)
            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), args), {envs = vcvars})

            batchcmds:set_depmtime(os.mtime(bmifile))
            batchcmds:set_depcache(target:dependfile(bmifile))

            local flag = {headerunitflag .. ":angle", headerunit.name .. "=" .. headerunit.name .. get_bmi_ext()}
            table.join2(private_flags, flag)
        end
    end

    return public_flags, private_flags
end

-- build module files
function build_modules(target, batchcmds, objectfiles, modules, opt)
    local cachedir = common.get_cache_dir(target)
    
    local compinst = target:compiler("cxx")
    local toolchain = target:toolchain("msvc")
    local vcvars = toolchain:config("vcvars")

    -- append deps modules
    for _, dep in ipairs(target:orderdeps()) do
        target:add("cxxflags", dep:data("cxx.modules.flags"), {force = true, expand = false})
    end

    -- compile module files to bmi files
    local common_args = {cxxsourcefileflag}
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
                table.join2(args, {interfaceflag, ifcoutputflag, bmifile, provide.sourcefile})

                batchcmds:add_depfiles(provide.sourcefile)
                batchcmds:set_depmtime(os.mtime(bmifile))
                batchcmds:set_depcache(target:dependfile(bmifile))

                flag = {"/reference", name .. "=" .. path.filename(bmifile)}
            end  

            batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_args, args, bmi_args), {envs = vcvars})

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
