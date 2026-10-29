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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      24bit-xjkp
-- @file        prepare_qml.lua
--

import("core.base.option")
import("core.base.json")
import("private.utils.batchcmds", {alias = "batchcmds_utils"})
import("utils.progress")
import("utils")
import("qrc")

-- is the given file compiled by qmltc?
function _is_qmltc_file(sourcefile)
    return path.extension(sourcefile):lower() == ".qml"
end

-- collect the qml files and the qmldir files of the module
function _collect_files(target, setting, sourcefiles)
    local qmls = {}
    local qmldirs = {}
    for _, sourcefile in ipairs(sourcefiles) do
        local alias, absfile = utils.get_alias(target, sourcefile)
        local filename = path.filename(sourcefile):lower()
        if filename == "qmldir" or path.extension(filename) == ".qmldir" then
            table.insert(qmldirs, {sourcefile = sourcefile, absfile = absfile})
        else
            table.insert(qmls, {
                sourcefile    = sourcefile,
                absfile       = absfile,
                alias         = alias,
                resource_path = utils.get_prefix(setting.uri) .. alias
            })
        end
    end
    if #qmldirs > 1 then
        wprint("qt.qml: multiple qmldir files are found in target(%s), only '%s' is packaged, " ..
            "all of them are used for imports", target:name(), qmldirs[1].sourcefile)
    end
    return qmls, qmldirs
end

-- write the module qrc and the file lists used by qmlcachegen/qmltc
function _write_files(target, setup)
    local setting = setup.setting
    local paths = setup.paths
    local qmls = setup.qmls
    local qmldirs = setup.qmldirs
    local qrcdata = {
        prefix  = utils.get_prefix(setting.uri),
        discard = setting.discard and true or false,
        qmldir  = qmldirs[1] and qmldirs[1].absfile or nil,
        entries = {}
    }
    for _, file in ipairs(qmls) do
        table.insert(qrcdata.entries, {alias = file.alias, path = file.absfile})
    end
    qrc.write_if_changed(paths.qrcfile, qrc.generate_qrc(qrcdata))
    if setup.need_cachegen then
        local rsp = {}
        for _, resource in ipairs(setup.resources) do
            table.insert(rsp, "--resource")
            table.insert(rsp, resource)
        end
        for _, file in ipairs(qmls) do
            table.insert(rsp, file.resource_path)
        end
        qrc.write_if_changed(paths.loaderrsp, table.concat(rsp, "\n") .. "\n")
    end
    if setup.need_qmltc then
        -- qmltc uses the file map to include the headers of the other components
        local mapdata = {entries = {}}
        for _, file in ipairs(qmls) do
            if _is_qmltc_file(file.sourcefile) then
                table.insert(mapdata.entries, {
                    alias = utils.get_qmltc_name(target, file.sourcefile) .. ".h",
                    path  = file.absfile
                })
            end
        end
        qrc.write_if_changed(paths.qmltcmap, qrc.generate_qrc(mapdata))
    end
end

-- get the qmltc generated files of the given qml file
function _get_qmltc_files(target, setup, sourcefile)
    local name = utils.get_qmltc_name(target, sourcefile)
    return {
        header = path.join(setup.paths.qmltcdir, name .. ".h"),
        impl   = path.join(setup.paths.qmltcdir, name .. ".cpp")
    }
end

-- add the generated sources to the target
--
-- They are compiled by the c++ rule in the build phase, the qmltc headers are
-- handled by the qt.moc rule, so we can reuse its moc detection and moc flags.
function _add_generated_files(target, setup, qmltc_files)
    local cppfiles = {}
    local headers = {}
    if setup.need_cachegen then
        for _, file in ipairs(setup.qmls) do
            table.insert(cppfiles, utils.get_autogen_file(target, "qmlcachegen", file.sourcefile, ".cpp"))
        end
        table.insert(cppfiles, setup.paths.loadercpp)
    end
    for _, file in ipairs(qmltc_files) do
        local files = _get_qmltc_files(target, setup, file.sourcefile)
        table.insert(cppfiles, files.impl)
        table.insert(headers, files.header)
    end
    if #cppfiles > 0 then
        target:add("files", cppfiles, {always_added = true})
    end
    -- the qt.moc rule reads the header to check Q_PRIVATE_SLOT, but the header does
    -- not exist in the dry run because the generation jobs are not executed
    if #headers > 0 and not option.get("dry-run") then
        target:add("files", headers, {rules = {"qt.moc", override = true}, always_added = true})
    end
end

-- add a dependency file, the order is stable, so the dependency cache can compare the list
function _add_depfile(depfiles, depset, filepath)
    filepath = path.normalize(filepath)
    if not depset[filepath] then
        depset[filepath] = true
        table.insert(depfiles, filepath)
    end
end

-- get the module files imported by the given module uri, e.g. MyApp.components
function _get_moduledeps(setup, modulename)
    local uri = setup.setting.uri
    local deps = {}
    if modulename == uri then
        for _, file in ipairs(setup.qmls) do
            table.insert(deps, file.absfile)
        end
    elseif modulename:startswith(uri .. ".") then
        local subdir = path.unix((modulename:sub(#uri + 2):gsub("%.", "/")))
        for _, file in ipairs(setup.qmls) do
            if path.unix(file.alias):startswith(subdir .. "/") then
                table.insert(deps, file.absfile)
            end
        end
    end
    return deps
end

-- get the qml/js files of the imported directory
function _get_directorydeps(setup, dir)
    local deps = {}
    -- `import "xxx.js"` is also reported as a directory import
    if os.isfile(dir) then
        table.insert(deps, dir)
        return deps
    end
    local found = false
    for _, file in ipairs(setup.qmls) do
        if utils.is_inside(file.absfile, dir) then
            table.insert(deps, file.absfile)
            found = true
        end
    end
    if not found then
        -- the directory is outside of the module, track all qml/js files in it
        for _, pattern in ipairs({"**.qml", "**.js", "**.mjs"}) do
            table.join2(deps, os.files(path.join(dir, pattern)))
        end
    end
    return deps
end

-- get the dependency files of the given source file
--
-- Every qml file only depends on itself, the files it imports and the qmldir
-- files of the module, so only the affected c++ sources are regenerated.
function _get_depfiles(target, setup, file)
    local depfiles = {file.absfile}
    local depset = {[file.absfile] = true}
    local scanfile = utils.get_autogen_file(target, "qmlimportscanner", file.sourcefile, ".json")
    local imports = try
    {
        function ()
            return json.loadfile(scanfile)
        end
    }
    if type(imports) == "table" then
        for _, import in ipairs(imports) do
            local importdeps
            if import.type == "module" then
                importdeps = _get_moduledeps(setup, import.name or "")
            elseif import.type == "directory" and import.path then
                local dir = import.path
                if not path.is_absolute(dir) then
                    dir = path.join(path.directory(file.absfile), dir)
                end
                importdeps = _get_directorydeps(setup, dir)
            elseif import.type == "javascript" and import.path then
                local jsfile = import.path
                if not path.is_absolute(jsfile) then
                    jsfile = path.join(path.directory(file.absfile), jsfile)
                end
                importdeps = os.isfile(jsfile) and {jsfile} or {}
            end
            for _, depfile in ipairs(importdeps or {}) do
                _add_depfile(depfiles, depset, depfile)
            end
        end
    else
        -- the scan output is missing, fall back to all module files to avoid stale sources
        for _, qmlfile in ipairs(setup.qmls) do
            _add_depfile(depfiles, depset, qmlfile.absfile)
        end
    end
    for _, qmldir in ipairs(setup.qmldirs) do
        _add_depfile(depfiles, depset, qmldir.absfile)
    end
    -- keep the list stable, xmake compares it with the recorded one in the dependency cache
    table.sort(depfiles)
    return depfiles
end

-- get the arguments shared by qmlcachegen and qmltc
function _add_import_args(args, setup)
    for _, dir in ipairs(setup.importdirs) do
        table.insert(args, "-I")
        table.insert(args, dir)
    end
    for _, qmldir in ipairs(setup.qmldirs) do
        table.insert(args, "-i")
        table.insert(args, qmldir.absfile)
    end
    for _, resource in ipairs(setup.resources) do
        table.insert(args, "--resource")
        table.insert(args, resource)
    end
end

-- scan the imports of the given qml/js file with qmlimportscanner, called by `batchcmds:call()`
function _scan_imports(scanfile, scanner, qmlfile, importdirs)
    local args = {}
    for _, dir in ipairs(importdirs) do
        table.insert(args, "-importPath")
        table.insert(args, dir)
    end
    table.insert(args, "-qmlFiles")
    table.insert(args, qmlfile)
    local outdata = try
    {
        function ()
            return os.iorunv(scanner, args)
        end,
        catch
        {
            function (errors)
                -- remove the stale result, it would be reused by the next builds because
                -- the source file is not changed, and the dependency graph would be frozen
                os.tryrm(scanfile)
                wprint("qt.qml: qmlimportscanner failed to scan %s: %s", qmlfile, errors)
            end
        }
    }
    if outdata and outdata ~= "" then
        os.mkdir(path.directory(scanfile))
        io.writefile(scanfile, outdata)
    else
        -- do not keep a stale dependency graph when the scanner produced no output
        os.tryrm(scanfile)
        wprint("qt.qml: qmlimportscanner returned no output for %s", qmlfile)
    end
end

-- add the import scan job of the given qml/js file, the result is the dependency graph of the module
function _add_scan(target, cmds, setup, file, opt)
    local scanfile = utils.get_autogen_file(target, "qmlimportscanner", file.sourcefile, ".json")
    cmds:show_progress(opt.progress, "${color.build.object}scanning.qt.qml.imports %s", file.sourcefile)
    cmds:call(_scan_imports, {scanfile, setup.tools.importscanner.program, file.absfile, setup.importdirs})
    cmds:add_depfiles(file.absfile)
    cmds:add_depvalues(setup.tools.importscanner.program, setup.importdirs)
    cmds:set_depmtime(os.mtime(scanfile))
    cmds:set_depcache(target:dependfile(scanfile))
end

-- generate the c++ source of the given qml/js/mjs file
function _add_cachegen(target, cmds, setup, file, opt)
    local cppfile = utils.get_autogen_file(target, "qmlcachegen", file.sourcefile, ".cpp")
    local args = {"--bare", "--resource-path", file.resource_path}
    _add_import_args(args, setup)
    if setup.setting.only_bytecode then
        table.insert(args, "--only-bytecode")
    end
    if setup.aot.enabled then
        table.insert(args, "--dump-aot-stats")
        table.insert(args, "--module-id=" .. setup.module_id)
    end
    table.insert(args, "-o")
    table.insert(args, cppfile)
    table.insert(args, file.absfile)
    cmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmlcachegen %s", file.sourcefile)
    cmds:mkdir(path.directory(cppfile))
    cmds:vrunv(setup.tools.cachegen.program, args)
    cmds:add_depfiles(_get_depfiles(target, setup, file))
    cmds:add_depvalues(setup.tools.cachegen.program, args)
    cmds:set_depmtime(os.mtime(cppfile))
    -- the dependency cache is maintained for every qml source file
    cmds:set_depcache(target:dependfile(file.absfile))
end

-- generate the qmlcache_loader
function _add_loader(target, cmds, setup, opt)
    local cppfile = setup.paths.loadercpp
    local args = {"--resource-name", "qmlcache_" .. target:name(),
        "-o", cppfile, "@" .. setup.paths.loaderrsp}
    cmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmlcachegen %s", path.filename(cppfile))
    cmds:mkdir(path.directory(cppfile))
    cmds:vrunv(setup.tools.cachegen.program, args)
    cmds:add_depfiles(setup.paths.loaderrsp)
    cmds:add_depvalues(setup.tools.cachegen.program, args)
    cmds:set_depmtime(os.mtime(cppfile))
    cmds:set_depcache(target:dependfile(cppfile))
end

-- write the existing sidecar files to the given list file, called by `batchcmds:call()`
function _write_aotstats_list(listfile, sidecars)
    local files = {}
    for _, file in ipairs(sidecars) do
        if os.isfile(file) then
            table.insert(files, file)
        end
    end
    os.mkdir(path.directory(listfile))
    io.writefile(listfile, #files > 0 and (table.concat(files, "\n") .. "\n") or "")
end

-- aggregate and format the aot compilation statistics
function _add_aotstats(target, cmds, setup, opt)
    local sidecars = {}
    for _, file in ipairs(setup.qmls) do
        local sidecar = utils.get_autogen_file(target, "qmlcachegen", file.sourcefile, ".cpp") .. ".aotstats"
        if os.isfile(sidecar) then
            table.insert(sidecars, sidecar)
        end
    end
    local paths = setup.paths
    if #sidecars == 0 then
        -- only qml components produce stats, e.g. a module with only .js files has none
        for _, filepath in ipairs({paths.aotstats, paths.aotstatstxt, paths.aotstatslist}) do
            if os.isfile(filepath) then
                cmds:rm(filepath)
            end
        end
        return
    end
    cmds:show_progress(opt.progress, "${color.build.object}generating.qt.qml.aotstats %s",
        path.filename(paths.aotstats))
    cmds:call(_write_aotstats_list, {paths.aotstatslist, sidecars})
    cmds:vrunv(setup.aot.tool.program, {"aggregate", paths.aotstatslist, paths.aotstats})
    cmds:vrunv(setup.aot.tool.program, {"format", paths.aotstats, paths.aotstatstxt})
    -- rebuild the report if any sidecar file has been regenerated
    cmds:add_depfiles(sidecars)
    cmds:add_depvalues(setup.aot.tool.program, paths.aotstatslist, paths.aotstats, paths.aotstatstxt)
    local reportexists = os.isfile(paths.aotstats) and os.isfile(paths.aotstatstxt)
    cmds:set_depmtime(reportexists and os.mtime(paths.aotstats) or 0)
    cmds:set_depcache(target:dependfile(paths.aotstats))
end

-- generate the qmltc source of the given qml file
function _add_qmltc(target, cmds, setup, file, opt)
    local files = _get_qmltc_files(target, setup, file.sourcefile)
    local args = {"--bare", "--header", files.header, "--impl", files.impl, "--module", setup.setting.uri}
    local namespace = setup.setting.namespace
    if namespace == nil then
        -- qmltc puts the generated types into an anonymous namespace by default and
        -- then components cannot include each other, use the module uri like Qt CMake does
        namespace = setup.setting.uri:gsub("%.", "::")
    end
    -- an empty namespace disables `--namespace`, e.g. to keep the anonymous namespace
    if namespace ~= "" then
        table.insert(args, "--namespace")
        table.insert(args, namespace)
    end
    _add_import_args(args, setup)
    -- the file map is used by qmltc to include the headers of other components
    table.insert(args, "--resource")
    table.insert(args, setup.paths.qmltcmap)
    table.insert(args, file.absfile)
    cmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmltc %s", file.sourcefile)
    cmds:mkdir(path.directory(files.header))
    cmds:vrunv(setup.tools.qmltc.program, args)
    cmds:add_depfiles(_get_depfiles(target, setup, file))
    cmds:add_depfiles(setup.paths.qmltcmap)
    cmds:add_depvalues(setup.tools.qmltc.program, args)
    -- qmltc keeps the mtime of an unchanged output, so we track the last run by the depend file
    local dependfile = target:dependfile(files.header)
    local outputsexist = os.isfile(files.header) and os.isfile(files.impl)
    cmds:set_depmtime(outputsexist and os.mtime(dependfile) or 0)
    cmds:set_depcache(dependfile)
end

-- add a generation job, the commands are skipped if the dependencies are not changed
function _add_job(jobgraph, name, target, run)
    jobgraph:add(name, function (_, _, opt)
        progress.set_target(opt.progress, target)
        local cmds = batchcmds_utils.new({target = target})
        run(cmds, opt)
        cmds:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
    end)
end

-- generate all sources in the prepare phase
--
-- The import scanner, qmlcachegen and qmltc jobs are scheduled in different groups,
-- so the qmlcachegen and qmltc jobs run in parallel after the imports are scanned.
function main(target, jobgraph, sourcebatch, opt)
    -- keep the generated files deterministic, so their content does not change
    -- between builds and the jobs do not rerun without a reason
    local sourcefiles = table.unique(sourcebatch.sourcefiles)
    table.sort(sourcefiles)
    if #sourcefiles == 0 then
        return
    end
    local setting = utils.get_setting(target)
    local needs = utils.get_needs(setting, sourcefiles)
    local qmls, qmldirs = _collect_files(target, setting, sourcefiles)
    local tools = utils.get_tools(target, setting, needs)
    local aot = utils.get_aot(target, setting, tools, needs)
    local paths = utils.get_paths(target)
    local dryrun = option.get("dry-run")
    local resourcebatch = target:sourcebatches()["qt.qml.resource"]
    local has_resources = resourcebatch ~= nil and #resourcebatch.sourcefiles > 0
    local resources = {paths.qrcfile}
    if has_resources then
        table.insert(resources, paths.resourceqrc)
    end
    local qmltc_sources = {}
    if setting.type_compiler then
        for _, file in ipairs(qmls) do
            if _is_qmltc_file(file.sourcefile) then
                table.insert(qmltc_sources, file)
            end
        end
    end
    local setup = {
        setting       = setting,
        tools         = tools,
        aot           = aot,
        paths         = paths,
        qmls          = qmls,
        qmldirs       = qmldirs,
        importdirs    = utils.get_importdirs(target, setting),
        resources     = resources,
        module_id     = setting.uri .. "(" .. target:name() .. ")",
        need_cachegen = needs.cachegen,
        need_qmltc    = needs.type_compiler and #qmltc_sources > 0
    }

    -- write the qrc file and the file lists in the prepare phase, the qrc files are
    -- compiled by the qt.qrc rule in the build phase
    --
    -- the dry run does not generate anything, and we also do not add the qrc file to
    -- the target, because the qt.qrc rule needs to read the qrc file to get its
    -- resource files, even in the dry run
    if not dryrun then
        _write_files(target, setup)
        target:add("files", paths.qrcfile, {always_added = true})
        -- remove the stale AOT report if the AOT compilation has been disabled
        if not aot.enabled then
            for _, filepath in ipairs({paths.aotstats, paths.aotstatstxt, paths.aotstatslist}) do
                if os.isfile(filepath) then
                    os.rm(filepath)
                end
            end
        end
    end

    -- the generated c++ sources are compiled by the c++ rule in the build phase,
    -- the qmltc headers are moc'ed by the qt.moc rule
    _add_generated_files(target, setup, qmltc_sources)
    if #qmltc_sources > 0 and not dryrun then
        target:add("includedirs", paths.qmltcdir)
    end

    local prefix = target:fullname() .. "/qt.qml"
    local need_qmltc = setup.need_qmltc

    -- the import scanner is only needed by the generated sources, qmltc only
    -- compiles the .qml files
    local scanfiles = {}
    if setup.need_cachegen then
        scanfiles = qmls
    elseif need_qmltc then
        scanfiles = qmltc_sources
    end
    local scangroup =  prefix .. "/qmlimportscanner"
    if #scanfiles > 0 then
        jobgraph:group(scangroup, function ()
            for _, file in ipairs(scanfiles) do
                _add_job(jobgraph, scangroup .. "/" .. file.sourcefile, target, function (cmds, jobopt)
                    _add_scan(target, cmds, setup, file, jobopt)
                end)
            end
        end)
    end

    if setup.need_cachegen then
        local cachegengroup = prefix .. "/qmlcachegen"
        jobgraph:group(cachegengroup, function ()
            for _, file in ipairs(qmls) do
                _add_job(jobgraph, cachegengroup .. "/" .. file.sourcefile, target, function (cmds, jobopt)
                    _add_cachegen(target, cmds, setup, file, jobopt)
                end)
            end
            _add_job(jobgraph, cachegengroup .. "/loader", target, function (cmds, jobopt)
                _add_loader(target, cmds, setup, jobopt)
            end)
        end)
        -- qmlcachegen reads the qrc files and the scan output
        jobgraph:add_orders(scangroup, cachegengroup)
        if aot.enabled then
            local aotstatsjob = prefix .. "/aotstats"
            _add_job(jobgraph, aotstatsjob, target, function (cmds, jobopt)
                _add_aotstats(target, cmds, setup, jobopt)
            end)
            jobgraph:add_orders(cachegengroup, aotstatsjob)
        end
    end

    if need_qmltc then
        local qmltcgroup = prefix .. "/qmltc"
        jobgraph:group(qmltcgroup, function ()
            for _, file in ipairs(qmltc_sources) do
                _add_job(jobgraph, qmltcgroup .. "/" .. file.sourcefile, target, function (cmds, jobopt)
                    _add_qmltc(target, cmds, setup, file, jobopt)
                end)
            end
        end)
        -- qmltc reads the qml files and the scan output, its headers are moc'ed by qt.moc
        jobgraph:add_orders(scangroup, qmltcgroup)
    end
end
