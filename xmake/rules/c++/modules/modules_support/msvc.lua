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
    table.insert(cache, path.translate(objectfile))
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
    local requiresflags = opt.requiresflags
    local flags = table.join("-TP", requiresflags or {}, compflags)

    -- trace
    progress.show(opt.progress, "${color.build.object}build.cxx.module %s", sourcefile)
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

-- build interface module file
function _build_interfacemodulefile(target, sourcefile, opt)
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
    local requiresflags = opt.requiresflags
    local interfaceflag = opt.interfaceflag
    local ifcoutputflag = opt.ifcoutputflag
    local bmifile = opt.bmifile
    local flags = table.join("-TP", requiresflags or {}, interfaceflag, ifcoutputflag, bmifile, compflags)

    -- trace
    progress.show(opt.progress, "${color.build.object}generating.cxx.module.bmi %s", opt.name)
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

    -- add stdifcdir in case of if the user ask for it
    local stdifcdirflag = get_stdifcdirflag(target)
    if stdifcdirflag then
        local msvc = target:toolchain("msvc")
        if msvc then
            local vcvars = msvc:config("vcvars")
            if vcvars.VCInstallDir and vcvars.VCToolsVersion then
                local arch
                if target:is_arch("x64", "x86_64") then
                    arch = "x64"
                elseif target:is_arch("x86", "i386") then
                    arch = "x86"
                end
                if arch then
                    local stdifcdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "ifc", arch)
                    if os.isdir(stdifcdir) then
                        target:add("cxxflags", {stdifcdirflag, winos.short_path(stdifcdir)}, {force = true, expand = false})
                    end
                end
            end
        end
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
    local toolchain = target:toolchain("msvc")
    local scandependenciesflag = nil -- get_scandependenciesflag(target)
    local scandependenciesflag = get_scandependenciesflag(target)
    local common_flags = {"-TP", scandependenciesflag}
    local cachedir = common.modules_cachedir(target)
    local changed = false
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function ()
            if opt.progress then
                progress.show(opt.progress, "${color.build.object}generating.cxx.module.deps %s", sourcefile)
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
                    local _includedirs = {}
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
                    local includedirs = {}
                    for i, includedir in pairs(_includedirs) do
                        table.insert(includedirs, "/I")
                        table.insert(includedirs, includedir)
                    end
                    local ifile = path.translate(path.join(outputdir, path.filename(file) .. ".i"))
                    os.vrunv(compinst:program(), table.join(includedirs, defines, {"/nologo", get_cppversionflag(target), "/P", "-TP", file,  "/Fi" .. ifile}), {envs = toolchain:runenvs()})
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
        progress.show((index * 100) / total, "${color.build.object}generating.cxx.headerunit.bmi %s", name)
        _compile(target, table.join(common_flags, flags))
        _add_objectfile_to_link_arguments(target, objectfile)
    end
end

-- generate header unit module bmi for batchcmds
function generate_headerunit_for_batchcmds(target, name, flags, objectfile, batchcmds, opt)
    local compinst = target:compiler("cxx")
    local msvc = target:toolchain("msvc")
    local common_flags = {"-TP", "-c"}
    batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.headerunit.bmi %s", name)
    batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_flags, flags), {envs = msvc:runenvs()})
    _add_objectfile_to_link_arguments(target, objectfile)
end

-- generate target stl header unit modules for batchjobs
function generate_stl_headerunits_for_batchjobs(target, batchjobs, headerunits, opt)
    local stlcachedir = common.stlmodules_cachedir(target)

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

    -- get flags
    local stlcachedir = common.stlmodules_cachedir(target)
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

    -- get flags
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

    -- flush job
    local flushjob = batchjobs:addjob(target:name() .. "_modules", function(index, total)
        _flush_mapper(target)
    end, {rootjob = opt.rootjob})

    local modulesjobs = {}
    for _, objectfile in ipairs(objectfiles) do
        local module = modules[objectfile]
        if module then
            if module.provides then
                -- assume there that provides is only one, until we encounter the case
                local length = 0
                local name, provide
                for k, v in pairs(module.provides) do
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
                    -- append module mapper flags first
                    -- @note we add it at the end to ensure that the full modulemap are already stored in the mapper
                    local requiresflags
                    if module.requires then
                        requiresflags = get_requiresflags(target, module.requires, {expand = true})
                    end

                    _build_interfacemodulefile(target, provide.sourcefile, {
                        objectfile = objectfile,
                        dependfile = target:dependfile(bmifile),
                        name = name,
                        bmifile = bmifile,
                        requiresflags = requiresflags,
                        interfaceflag = interfaceflag,
                        ifcoutputflag = ifcoutputflag,
                        progress = (index * 100) / total})

                    _add_module_to_mapper(target, referenceflag, name, name, objectfile, bmifile, requiresflags)
                end)
                if module.requires then
                    moduleinfo.deps = table.keys(module.requires)
                end
                moduleinfo.name = name
                modulesjobs[name] = moduleinfo
                target:add("objectfiles", objectfile)
            else
                modulesjobs[module.cppfile] = {
                    name = module.cppfile,
                    deps = table.keys(module.requires or {}),
                    sourcefile = module.cppfile,
                    job = batchjobs:newjob(module.cppfile, function(index, total)
                        local requiresflags
                        if module.requires then
                            requiresflags = get_requiresflags(target, module.requires, {expand = true})
                        end

                        if common.has_module_extension(module.cppfile) then
                            _build_modulefile(target, module.cppfile, {
                                objectfile = objectfile,
                                dependfile = target:dependfile(objectfile),
                                requiresflags = requiresflags,
                                progress = (index * 100) / total})
                            target:add("objectfiles", objectfile)
                        elseif requiresflags then
                            -- append module mapper flags
                            -- @note we add it at the end to ensure that the full modulemap are already stored in the mapper
                            local requiresflags = get_requiresflags(target, module.requires)
                            target:fileconfig_add(module.cppfile, {force = {cxxflags = requiresflags}})
                        end
                    end)
                }
            end
        end
    end

    -- build batchjobs for modules
    common.build_batchjobs_for_modules(modulesjobs, batchjobs, flushjob)
end

-- build module files for batchcmds
function build_modules_for_batchcmds(target, batchcmds, objectfiles, modules, opt)
    local compinst = target:compiler("cxx")
    local msvc = target:toolchain("msvc")

    -- get flags
    local ifcoutputflag = get_ifcoutputflag(target)
    local interfaceflag = get_interfaceflag(target)
    local referenceflag = get_referenceflag(target)

    -- build modules
    local common_flags = {"-TP"}
    local depmtime = 0
    for _, objectfile in ipairs(objectfiles) do
        local module = modules[objectfile]
        if module then
            if module.provides then
                local name, provide
                for k, v in pairs(module.provides) do
                    name = k
                    provide = v
                    break
                end

                -- append required modulemap flags to module
                local requiresflags
                if module.requires then
                    requiresflags = get_requiresflags(target, module.requires, {expand = true})
                end

                local bmifile = provide.bmi
                local flags = {"-c",
                    path(objectfile, function (p) return "-Fo" .. p end),
                    interfaceflag,
                    ifcoutputflag,
                    path(bmifile),
                    path(provide.sourcefile)}
                batchcmds:show_progress(opt.progress, "${color.build.object}generating.cxx.module.bmi %s", name)
                batchcmds:mkdir(path.directory(objectfile))
                batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), common_flags, requiresflags or {}, flags), {envs = msvc:runenvs()})
                batchcmds:add_depfiles(provide.sourcefile)
                target:add("objectfiles", objectfile)
                _add_module_to_mapper(target, referenceflag, name, name, objectfile, bmifile, requiresflags)
                depmtime = math.max(depmtime, os.mtime(bmifile))
            else
                local requiresflags
                if module.requires then
                    requiresflags = get_requiresflags(target, module.requires, {expand = true})
                end

                if common.has_module_extension(module.cppfile) then
                    local flags = {"-c",
                        path(objectfile, function (p) return "-Fo" .. p end),
                        path(module.cppfile)}
                    batchcmds:show_progress(opt.progress, "${color.build.object}build.cxx.module %s", module.cppfile)
                    batchcmds:mkdir(path.directory(objectfile))
                    batchcmds:vrunv(compinst:program(), table.join(compinst:compflags({target = target}), requiresflags or {}, flags), {envs = msvc:runenvs()})
                    batchcmds:add_depfiles(module.cppfile)
                    target:add("objectfiles", objectfile)
                    depmtime = math.max(depmtime, os.mtime(objectfile))
                elseif requiresflags then
                    target:fileconfig_add(module.cppfile, {force = {cxxflags = requiresflags}})
                end
            end
        end
    end

    batchcmds:set_depmtime(depmtime)
    _flush_mapper(target)
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

function get_stdifcdirflag(target)
    local stdifcdirflag = _g.stdifcdirflag
    if stdifcdirflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-stdIfcDir", "cxxflags", {flagskey = "cl_std_ifc_dir"}) then
            stdifcdirflag = "-stdIfcDir"
        end
        _g.stdifcdirflag = stdifcdirflag or false
    end
    return stdifcdirflag or nil
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
    for name, _ in table.orderpairs(requires) do
        for _, dep in ipairs(target:orderdeps()) do
            local modulemap_ = _get_modulemap_from_mapper(dep)
            if modulemap_[name] then
                table.join2(flags, modulemap_[name].flag)
                table.join2(flags, modulemap_[name].deps or {})
                if os.isfile(modulemap_[name].objectfile) then
                    _add_objectfile_to_link_arguments(target, modulemap_[name].objectfile)
                end
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
