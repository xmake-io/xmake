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
-- @author      ruki, Arthapz
-- @file        msvc.lua
--

-- imports
import("core.base.option")
import("core.tool.compiler")
import("core.project.project")
import("core.project.depend")
import("core.project.config")
import("core.base.hashset")
import("core.base.semver")
import("utils.progress")
import("private.action.build.object", {alias = "objectbuilder"})
import("common")

-- add a module or header unit into the mapper
--
-- e.g
-- /reference Foo=build/.gens/Foo/rules/modules/cache/Foo.ifc
-- /headerUnit:angle glm/mat4x4.hpp=Users\arthu\AppData\Local\.xmake\packages\g\glm\0.9.9+8\91454f3ee0be416cb9c7452970a2300f\include\glm\mat4x4.hpp.ifc
--
function _add_module_to_mapper(target, argument, namekey, path, objectfile, bmifile, deps)
    local modulemap = _get_modulemap_from_mapper(target)
    if modulemap[namekey] then
        return
    end
    local mapflag = {argument, path .. "=" .. bmifile}
    modulemap[namekey] = {flag = mapflag, objectfile = objectfile, deps = deps}
    common.localcache():set2(_mapper_cachekey(target), "modulemap", modulemap)
end

function _mapper_cachekey(target)
    local mode = config.mode()
    return target:name() .. "_modulemap_" .. (mode or "")
end

-- flush mapper file cache
function _flush_mapper(target)
    -- not using set2/get2 to flush only current target mapper
    common.localcache():save(_mapper_cachekey(target))
end

-- get modulemap from mapper
function _get_modulemap_from_mapper(target)
    return common.localcache():get2(_mapper_cachekey(target), "modulemap") or {}
end

-- do compile
function _compile(target, flags)
    local compinst = target:compiler("cxx")
    local msvc = target:toolchain("msvc")
    os.vrunv(compinst:program(), winos.cmdargv(table.join(compinst:compflags({target = target}), flags)), {envs = msvc:runenvs()})
end

-- do compile for batchcmds
-- @note we need use batchcmds:compilev to translate paths in compflags for generator, e.g. -Ixx
function _batchcmds_compile(batchcmds, target, flags)
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({target = target})
    batchcmds:compilev(table.join(compflags or {}, flags), {compiler = compinst, sourcekind = "cxx"})
end

-- add an objectfile to the linker flags
--
-- e.g
-- foo.obj
--
function _add_objectfile_to_link_arguments(target, objectfile)
    local cachekey = target:name() .. "dependency_objectfiles"
    local cache = common.localcache():get(cachekey) or {}
    if table.contains(cache, objectfile) then
        return
    end
    table.insert(cache, objectfile)
    common.localcache():set(cachekey, cache)
    common.localcache():save(cachekey)
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

    -- init flags
    local flags = table.join("-TP", compflags, opt.flags or {})

    -- trace
    progress.show(opt.progress, "${color.build.object}compiling.module.$(mode) %s", opt.name)
    vprint(compinst:compcmd(sourcefile, objectfile, {compflags = flags, rawargs = true}))

    if not dryrun then

        -- do compile
        dependinfo.files = {}
        assert(compinst:compile(sourcefile, objectfile, {dependinfo = dependinfo, compflags = flags}))

        -- update files and values to the dependent file
        dependinfo.values = depvalues
        table.join2(dependinfo.files, sourcefile)
        depend.save(dependinfo, dependfile)
    end
end

-- load module support for the current target
function load(target)

    -- add modules flags
    local modulesflag = get_modulesflag(target)
    target:add("cxxflags", modulesflag)

    -- enable std modules if c++23 by defaults
    if target:data("c++.msvc.enable_std_import") == nil then
        local languages = target:get("languages")
        local isatleastcpp23 = false
        for _, language in ipairs(languages) do
            if language:startswith("c++") or language:startswith("cxx") then
                isatleastcpp23 = true
                local version = tonumber(language:match("%d+"))
                if (not version or version <= 20) and not language:match("latest") then
                    isatleastcpp23 = false
                    break
                end
            end
        end
        local stdmodulesdir
        local msvc = target:toolchain("msvc")
        if msvc then
            local vcvars = msvc:config("vcvars")
            if vcvars.VCInstallDir and vcvars.VCToolsVersion and semver.compare(vcvars.VCToolsVersion, "14.35") then
                stdmodulesdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "modules")
            end
        end
        target:data_set("c++.msvc.enable_std_import", isatleastcpp23 and os.isdir(stdmodulesdir))
    end
end

-- provide toolchain include dir for stl headerunit when p1689 is not supported
function toolchain_includedirs(target)
    for _, toolchain_inst in ipairs(target:toolchains()) do
        if toolchain_inst:name() == "msvc" then
            local vcvars = toolchain_inst:config("vcvars")
            if vcvars.VCInstallDir and vcvars.VCToolsVersion then
                return { path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "include") }
            end
            break
        end
    end
    raise("msvc toolchain includedirs not found!")
end

-- generate dependency files
function generate_dependencies(target, sourcebatch, opt)
    local msvc = target:toolchain("msvc")
    local scandependenciesflag = get_scandependenciesflag(target)
    local common_flags = {"-TP", scandependenciesflag}
    local cachedir = common.modules_cachedir(target)
    local changed = false
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function ()
            if opt.progress then
                progress.show(opt.progress, "${color.build.object}generating.module.deps %s", sourcefile)
            end
            local outputdir = path.join(cachedir, path.directory(path.relative(sourcefile, projectdir)))
            if not os.isdir(outputdir) then
                os.mkdir(outputdir)
            end

            local jsonfile = path.join(outputdir, path.filename(sourcefile) .. ".json")
            if scandependenciesflag then
                local flags = {jsonfile, sourcefile, "-Fo" .. target:objectfile(sourcefile)}
                _compile(target, table.join(common_flags, flags))
            else
                common.fallback_generate_dependencies(target, jsonfile, sourcefile, function(file)
                    local compinst = target:compiler("cxx")
                    local defines = {}
                    for _, define in ipairs(target:get("defines")) do
                        table.insert(defines, "/D" .. define)
                    end
                    local _includedirs = table.join({}, target:get("includedirs"))
                    for _, dep in ipairs(target:orderdeps()) do
                        local includedir = dep:get("sysincludedirs") or dep:get("includedirs")
                        if includedir then
                            table.join2(_includedirs, includedir)
                        end
                    end
                    for _, pkg in pairs(target:pkgs()) do
                        local includedir = pkg:get("sysincludedirs") or pkg:get("includedirs")
                        if includedir then
                            table.join2(_includedirs, includedir)
                        end
                    end
                    local includedirs = {}
                    for _, includedir in pairs(_includedirs) do
                        table.insert(includedirs, "/I")
                        table.insert(includedirs, includedir)
                    end
                    local ifile = path.translate(path.join(outputdir, path.filename(file) .. ".i"))
                    os.vrunv(compinst:program(), table.join(includedirs, defines,
                        {"/nologo", get_cppversionflag(target), "/P", "-TP", file,  "/Fi" .. ifile}), {envs = msvc:runenvs()})
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

-- generate header unit module bmi for batchjobs
function generate_headerunit_for_batchjob(target, name, flags, objectfile, index, total)
    -- don't generate same header unit bmi at the same time across targets
    if not common.memcache():get2(name, "generating") then
        local common_flags = {"-TP", "-c"}
        common.memcache():set2(name, "generating", true)
        progress.show((index * 100) / total, "${color.build.object}compiling.headerunit.$(mode) %s", name)
        _compile(target, table.join(common_flags, flags))
        _add_objectfile_to_link_arguments(target, objectfile)
    end
end

-- generate header unit module bmi for batchcmds
function generate_headerunit_for_batchcmds(target, name, flags, objectfile, batchcmds, opt)
    local common_flags = {"-TP", "-c"}
    batchcmds:show_progress(opt.progress, "${color.build.object}compiling.headerunit.$(mode) %s", name)
    _batchcmds_compile(batchcmds, target, table.join(common_flags, flags))
    _add_objectfile_to_link_arguments(target, objectfile)
end

-- generate target stl header unit modules for batchjobs
function generate_stl_headerunits_for_batchjobs(target, batchjobs, headerunits, opt)
    local stlcachedir = common.stlmodules_cachedir(target, {mkdir = true})

    -- get flags
    local exportheaderflag = get_exportheaderflag(target)
    local headerunitflag = get_headerunitflag(target)
    local headernameflag = get_headernameflag(target)
    local ifcoutputflag = get_ifcoutputflag(target)
    assert(headerunitflag and headernameflag and exportheaderflag, "compiler(msvc): does not support c++ header units!")

    -- flush job
    local flushjob = batchjobs:addjob(target:name() .. "_stl_headerunits_flush_mapper", function(index, total)
        _flush_mapper(target)
    end, {rootjob = opt.rootjob})

    -- build headerunits
    for _, headerunit in ipairs(headerunits) do
        local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_extension())
        local objectfile = bmifile .. ".obj"
        batchjobs:addjob(headerunit.name, function(index, total)
            depend.on_changed(function()
                local flags = {
                    exportheaderflag,
                    headernameflag .. ":angle",
                    headerunit.name,
                    ifcoutputflag,
                    headerunit.name:startswith("experimental/") and path.join(stlcachedir, "experimental") or stlcachedir,
                    "-Fo" .. objectfile
                }
                generate_headerunit_for_batchjob(target, headerunit.name, flags, objectfile, index, total)

            end, {dependfile = target:dependfile(bmifile), files = {headerunit.path}})
            _add_module_to_mapper(target, headerunitflag .. ":angle", headerunit.name, headerunit.name, objectfile, bmifile)
        end, {rootjob = flushjob})
    end
end

-- generate target stl header units for batchcmds
function generate_stl_headerunits_for_batchcmds(target, batchcmds, headerunits, opt)
    local stlcachedir = common.stlmodules_cachedir(target, {mkdir = true})
    local exportheaderflag = get_exportheaderflag(target)
    local headerunitflag = get_headerunitflag(target)
    local headernameflag = get_headernameflag(target)
    local ifcoutputflag = get_ifcoutputflag(target)
    assert(headerunitflag and headernameflag and exportheaderflag, "compiler(msvc): does not support c++ header units!")

    -- build headerunits
    local depmtime = 0
    for _, headerunit in ipairs(headerunits) do
        local bmifile = path.join(stlcachedir, headerunit.name .. get_bmi_extension())
        local objectfile = bmifile .. ".obj"
        local flags = {
            exportheaderflag,
            headernameflag .. ":angle",
            headerunit.name,
            ifcoutputflag,
            path(headerunit.name:startswith("experimental/") and path.join(stlcachedir, "experimental") or stlcachedir),
            path(objectfile, function (p) return "-Fo" .. p end)}
        generate_headerunit_for_batchcmds(target, headerunit.name, flags, objectfile, batchcmds, opt)
        batchcmds:add_depfiles(headerunit.path)
        _add_module_to_mapper(target, headerunitflag .. ":angle", headerunit.name, headerunit.name, objectfile, bmifile)
        depmtime = math.max(depmtime, os.mtime(bmifile))
    end
    batchcmds:set_depmtime(depmtime)
    _flush_mapper(target)
end

-- generate target user header units for batchcmds
function generate_user_headerunits_for_batchjobs(target, batchjobs, headerunits, opt)
    local cachedir = common.modules_cachedir(target)

    -- get flags
    local exportheaderflag = get_exportheaderflag(target)
    local headerunitflag = get_headerunitflag(target)
    local headernameflag = get_headernameflag(target)
    local ifcoutputflag = get_ifcoutputflag(target)
    assert(headerunitflag and headernameflag and exportheaderflag, "compiler(msvc): does not support c++ header units!")

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
            -- if path is relative then its a subtarget path
            outputdir = path.join(cachedir, path.is_absolute(headerunit.path) and path.directory(headerunit.path):sub(3) or headerunit.path)
        end
        local bmifilename = path.basename(objectfile) .. get_bmi_extension()
        local bmifile = path.join(outputdir, bmifilename)
        batchjobs:addjob(headerunit.name, function (index, total)
            depend.on_changed(function()
                local objectdir = path.directory(objectfile)
                if not os.isdir(objectdir) then
                    os.mkdir(objectdir)
                end
                if not os.isdir(outputdir) then
                    os.mkdir(outputdir)
                end

                -- generate headerunit
                local flags = {
                    exportheaderflag,
                    headernameflag .. headerunit.type,
                    headerunit.path,
                    ifcoutputflag,
                    outputdir,
                    "/Fo" .. objectfile
                }
                generate_headerunit_for_batchjob(target, headerunit.unique and path.filename(headerunit.name) or headerunit.name, flags, objectfile, index, total)

            end, {dependfile = target:dependfile(bmifile), files = {headerunit.path}})
            _add_module_to_mapper(target, headerunitflag .. headerunit.type, headerunit.name, headerunit.type == ":quote" and headerunit.path or headerunit.name, objectfile,  bmifile)
        end, {rootjob = flushjob})
    end
end

-- generate target user header units for batchcmds
function generate_user_headerunits_for_batchcmds(target, batchcmds, headerunits, opt)
    local cachedir = common.modules_cachedir(target)
    local exportheaderflag = get_exportheaderflag(target)
    local headerunitflag = get_headerunitflag(target)
    local headernameflag = get_headernameflag(target)
    local ifcoutputflag = get_ifcoutputflag(target)
    assert(headerunitflag and headernameflag and exportheaderflag, "compiler(msvc): does not support c++ header units!")

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
            -- if path is relative then its a subtarget path
            outputdir = path.join(cachedir, path.is_absolute(headerunit.path) and path.directory(headerunit.path):sub(3) or headerunit.path)
        end
        batchcmds:mkdir(outputdir)

        local bmifilename = path.basename(objectfile) .. get_bmi_extension()
        local bmifile = path.join(outputdir, bmifilename)
        batchcmds:mkdir(path.directory(objectfile))

        local flags = {
            exportheaderflag,
            headernameflag .. headerunit.type,
            headerunit.path,
            ifcoutputflag,
            outputdir,
            "/Fo" .. objectfile
        }
        generate_headerunit_for_batchcmds(target, headerunit.unique and path.filename(headerunit.name) or headerunit.name, flags, objectfile, batchcmds, opt)
        batchcmds:add_depfiles(headerunit.path)

        _add_module_to_mapper(target, headerunitflag .. headerunit.type, headerunit.name, headerunit.type == ":quote" and headerunit.path or headerunit.name, objectfile,  bmifile)

        depmtime = math.max(depmtime, os.mtime(bmifile))
    end
    batchcmds:set_depmtime(depmtime)
    _flush_mapper(target)
end

-- build module files for batchjobs
function build_modules_for_batchjobs(target, batchjobs, objectfiles, modules, opt)

    -- get flags
    local ifcoutputflag = get_ifcoutputflag(target)
    local interfaceflag = get_interfaceflag(target)
    local referenceflag = get_referenceflag(target)
    local internalpartitionflag = get_internalpartitionflag(target)

    -- flush job
    local flushjob = batchjobs:addjob(target:name() .. "_modules", function(index, total)
        _flush_mapper(target)
    end, {rootjob = opt.rootjob})

    if target:data("c++.msvc.enable_std_import") then
        for objectfile, module in pairs(get_stdmodules(target)) do
            table.insert(objectfiles, objectfile)
            modules[objectfile] = module
        end
    end

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
            local flags = {"-TP"}
            local dependfile = target:dependfile(objectfile)

            if provide then
                table.join2(flags, {ifcoutputflag, path(provide.bmi), provide.interface and interfaceflag or internalpartitionflag})
                dependfile = target:dependfile(provide.bmi)
            end

            table.join2(moduleinfo, {
                name = name or cppfile,
                deps = table.keys(module.requires or {}),
                sourcefile = cppfile,
                job = batchjobs:newjob(name or cppfile, function(index, total)
                    -- append module mapper flags first
                    -- @note we add it at the end to ensure that the full modulemap are already stored in the mapper
                    local requiresflags
                    if module.requires then
                        requiresflags = get_requiresflags(target, module.requires, {expand = true})
                    end
                    local _flags = table.join(flags, requiresflags or {})

                    if provide or common.has_module_extension(cppfile) then
                        if not common.memcache():get2(name or cppfile, "compiling") then
                            if name and name:match("std") then
                            common.memcache():set2(name or cppfile, "compiling", true)
                            end
                        _build_modulefile(target, cppfile, {
                            objectfile = objectfile,
                            dependfile = dependfile,
                            name = name or module.cppfile,
                            flags = _flags,
                            progress = (index * 100) / total})
                        _add_objectfile_to_link_arguments(target, path(objectfile))
                        end
                    elseif requiresflags then
                        requiresflags = get_requiresflags(target, module.requires)
                        target:fileconfig_add(cppfile, {force = {cxxflags = table.join(flags, requiresflags)}})
                    end

                    if provide then
                        _add_module_to_mapper(target, referenceflag, name, name, objectfile, provide.bmi, requiresflags)
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

    -- get flags
    local ifcoutputflag = get_ifcoutputflag(target)
    local interfaceflag = get_interfaceflag(target)
    local referenceflag = get_referenceflag(target)
    local internalpartitionflag = get_internalpartitionflag(target)

    if target:data("c++.msvc.enable_std_import") then
        for objectfile, module in pairs(get_stdmodules(target)) do
            table.insert(objectfiles, objectfile)
            modules[objectfile] = module
        end
    end

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
            -- append required modulemap flags to module
            local requiresflags
            if module.requires then
                requiresflags = get_requiresflags(target, module.requires, {expand = true})
            end

            local flags = table.join({"-TP", "-c", path(cppfile), path(objectfile, function (p) return "-Fo" .. p end)})
            if provide or common.has_module_extension(cppfile) then
                if provide then
                    table.join2(flags, {ifcoutputflag, path(provide.bmi), provide.interface and interfaceflag or internalpartitionflag})
                end

                batchcmds:show_progress(opt.progress, "${color.build.object}compiling.module.$(mode) %s", name or cppfile)
                batchcmds:mkdir(path.directory(objectfile))
                _batchcmds_compile(batchcmds, target, table.join(flags, requiresflags or {}))
                batchcmds:add_depfiles(cppfile)
                _add_objectfile_to_link_arguments(target, path(objectfile))
                if provide then
                    _add_module_to_mapper(target, referenceflag, name, name, objectfile, provide.bmi, requiresflags)
                end
                depmtime = math.max(depmtime, os.mtime(provide and provide.bmi or objectfile))
            elseif requiresflags then
                requiresflags = get_requiresflags(target, module.requires)
                target:fileconfig_add(cppfile, {force = {cxxflags = table.join(flags, requiresflags)}})
            end
        end
    end

    batchcmds:set_depmtime(depmtime)
    _flush_mapper(target)
end

function get_stdmodules(target)
    local modules = {}

    -- build c++23 standard modules if needed
    if target:data("c++.msvc.enable_std_import") then
        local msvc = target:toolchain("msvc")
        if msvc then
            local vcvars = msvc:config("vcvars")
            if vcvars.VCInstallDir and vcvars.VCToolsVersion then
                local stdmodulesdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "modules")
                assert(stdmodulesdir, "Can't enable C++23 std modules, directory missing !")

                local stlcachedir = common.stlmodules_cachedir(target)
                local modulefile = path.join(stdmodulesdir, "std.ixx")
                local bmifile = path.join(stlcachedir, "std.ixx" .. get_bmi_extension())
                local objfile = bmifile .. ".obj"
                modules[objfile] = {provides = {std = {interface = true, sourcefile = modulefile, bmi = bmifile}}}
                stlcachedir = common.stlmodules_cachedir(target)
                modulefile = path.join(stdmodulesdir, "std.compat.ixx")
                bmifile = path.join(stlcachedir, "std.compat.ixx" .. get_bmi_extension())
                objfile = bmifile .. ".obj"
                modules[objfile] = {provides = {["std.compat"] = {interface = true, sourcefile = modulefile, bmi = bmifile}}, requires = {std = {unique = false, method = "by-name"}}}
            end
        end
    end
    return modules
end

function get_bmi_extension()
    return ".ifc"
end

function get_modulesflag(target)
    local modulesflag = _g.modulesflag
    if modulesflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-experimental:module", "cxxflags", {flagskey = "cl_experimental_module"}) then
            modulesflag = "-experimental:module"
        end
        assert(modulesflag, "compiler(msvc): does not support c++ module!")
        _g.modulesflag = modulesflag or false
    end
    return modulesflag or nil
end

function get_ifcoutputflag(target)
    local ifcoutputflag = _g.ifcoutputflag
    if ifcoutputflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-ifcOutput", "cxxflags", {flagskey = "cl_ifc_output"})  then
            ifcoutputflag = "-ifcOutput"
        end
        assert(ifcoutputflag, "compiler(msvc): does not support c++ module!")
        _g.ifcoutputflag = ifcoutputflag or false
    end
    return ifcoutputflag or nil
end

function get_ifcsearchdirflag(target)
    local ifcsearchdirflag = _g.ifcsearchdirflag
    if ifcsearchdirflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-ifcSearchDir", "cxxflags", {flagskey = "cl_ifc_search_dir"})  then
            ifcsearchdirflag = "-ifcSearchDir"
        end
        assert(ifcsearchdirflag, "compiler(msvc): does not support c++ module!")
        _g.ifcsearchdirflag = ifcsearchdirflag or false
    end
    return ifcsearchdirflag or nil
end

function get_interfaceflag(target)
    local interfaceflag = _g.interfaceflag
    if interfaceflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-interface", "cxxflags", {flagskey = "cl_interface"}) then
            interfaceflag = "-interface"
        end
        assert(interfaceflag, "compiler(msvc): does not support c++ module!")
        _g.interfaceflag = interfaceflag or false
    end
    return interfaceflag
end

function get_referenceflag(target)
    local referenceflag = _g.referenceflag
    if referenceflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-reference", "cxxflags", {flagskey = "cl_reference"}) then
            referenceflag = "-reference"
        end
        assert(referenceflag, "compiler(msvc): does not support c++ module!")
        _g.referenceflag = referenceflag or false
    end
    return referenceflag or nil
end

function get_headernameflag(target)
    local headernameflag = _g.headernameflag
    if headernameflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-headerName:quote", "cxxflags", {flagskey = "cl_header_name_quote"}) and
        compinst:has_flags("-headerName:angle", "cxxflags", {flagskey = "cl_header_name_angle"}) then
            headernameflag = "-headerName"
        end
        _g.headernameflag = headernameflag or false
    end
    return headernameflag or nil
end

function get_headerunitflag(target)
    local headerunitflag = _g.headerunitflag
    if headerunitflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-headerUnit:quote", "cxxflags", {flagskey = "cl_header_unit_quote"}) and
        compinst:has_flags("-headerUnit:angle", "cxxflags", {flagskey = "cl_header_unit_angle"}) then
            headerunitflag = "-headerUnit"
        end
        _g.headerunitflag = headerunitflag or false
    end
    return headerunitflag or nil
end

function get_exportheaderflag(target)
    local modulesflag = get_modulesflag(target)
    local exportheaderflag = _g.exportheaderflag
    if exportheaderflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags(modulesflag .. " -exportHeader", "cxxflags", {flagskey = "cl_export_header"}) then
            exportheaderflag = "-exportHeader"
        end
        _g.exportheaderflag = exportheaderflag or false
    end
    return exportheaderflag or nil
end

function get_scandependenciesflag(target)
    local scandependenciesflag = _g.scandependenciesflag
    if scandependenciesflag == nil then
        local compinst = target:compiler("cxx")
        local scan_dependencies_jsonfile = os.tmpfile() .. ".json"
        if compinst:has_flags("-scanDependencies " .. scan_dependencies_jsonfile, "cxflags", {flagskey = "cl_scan_dependencies",
            on_check = function (ok, errors)
                if os.isfile(scan_dependencies_jsonfile) then
                    ok = true
                end
                if ok and not os.isfile(scan_dependencies_jsonfile) then
                    ok = false
                end
                return ok, errors
            end}) then
            scandependenciesflag = "-scanDependencies"
        end
        _g.scandependenciesflag = scandependenciesflag or false
    end
    return scandependenciesflag or nil
end

-- get requireflags from module mapper
function get_requiresflags(target, requires, opt)
    opt = opt or {}
    local flags = {}
    local modulemap = _get_modulemap_from_mapper(target)
    -- add deps required module flags
    local already_mapped_modules = {}
    for name, _ in table.orderpairs(requires) do
        -- if already in flags, continue
        if already_mapped_modules[name] then
            goto continue
        end

        for _, dep in ipairs(target:orderdeps()) do
            local modulemap_ = _get_modulemap_from_mapper(dep)
            if modulemap_[name] then
                table.join2(flags, modulemap_[name].flag)
                table.join2(flags, modulemap_[name].deps or {})
                already_mapped_modules[name] = true
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
    local requireflags = {}
    local contains = {}
    for i = 1, #flags, 2 do
        local value = flags[i + 1]
        if not contains[value] then
            local key = flags[i]
            if opt.expand then
                table.insert(requireflags, key)
                table.insert(requireflags, value)
            else
                table.insert(requireflags, {key, value})
            end
            contains[value] = true
        end
    end
    if #requireflags > 0 then
        return requireflags
    end
end

function get_cppversionflag(target)
    local cppversionflag = _g.cppversionflag
    if cppversionflag == nil then
        local compinst = target:compiler("cxx")
        local flags = compinst:compflags({target = target})
        cppversionflag = table.find_if(flags, function(v) string.startswith(v, "/std:c++") end) or "/std:c++latest"
    end
    return cppversionflag or nil
end

function get_internalpartitionflag(target)
    local internalpartitionflag = _g.internalpartitionflag
    if internalpartitionflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-internalPartition", "cxxflags", {flagskey = "cl_internal_partition"}) then
            internalpartitionflag = "-internalPartition"
        end
        _g.internalpartitionflag = internalpartitionflag or false
    end
    return internalpartitionflag or nil
end
