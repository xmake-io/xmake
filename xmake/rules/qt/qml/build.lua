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
-- @file        build.lua
--

-- imports
import("core.base.option")
import("core.base.json")
import("private.utils.batchcmds", {alias = "batchcmds_utils"})
import("utils.progress")
import("utils")

-- get the path of the helper lua scripts, they are run by `batchcmds:lua()`
function _get_script(scriptname)
    return path.join(os.programdir(), "rules", "qt", "qml", scriptname)
end

-- is the given file compiled by qmltc?
function _is_qmltc_file(sourcefile)
    return path.extension(sourcefile):lower() == ".qml"
end

-- get the qmltc generated files of the given qml file
function _get_qmltc_files(target, setup, sourcefile)
    local name = utils.get_qmltc_name(target, sourcefile)
    return {
        header = path.join(setup.paths.qmltc, name .. ".h"),
        impl   = path.join(setup.paths.qmltc, name .. ".cpp"),
        moc    = path.join(setup.paths.qmltc, "moc_" .. name .. ".cpp")
    }
end

-- get the generated c++ sources
function _get_cppfiles(target, setup)
    local cppfiles = {}
    if setup.need_cachegen then
        for _, file in ipairs(setup.qmls) do
            table.insert(cppfiles, utils.get_autogen_file(target, "qmlcachegen", file.sourcefile, ".cpp"))
        end
        table.insert(cppfiles, setup.paths.loadercpp)
    end
    if setup.setting.type_compiler then
        for _, file in ipairs(setup.qmls) do
            if _is_qmltc_file(file.sourcefile) then
                local files = _get_qmltc_files(target, setup, file.sourcefile)
                table.insert(cppfiles, files.impl)
                table.insert(cppfiles, files.moc)
            end
        end
    end
    return cppfiles
end

-- add the generated c++ sources to the target, xmake rescans the job graph for
-- the build phase, so the c++.build rule compiles them
function _add_cppfiles(target, setup)
    local cppfiles = _get_cppfiles(target, setup)
    if #cppfiles > 0 then
        target:add("files", cppfiles, {always_added = true})
    end
end

-- get the file which caches the imports of the given source file
function _get_scanfile(target, sourcefile)
    return utils.get_autogen_file(target, "qmlimportscanner", sourcefile, ".json")
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
    local imports = try
    {
        function ()
            return json.loadfile(_get_scanfile(target, file.sourcefile))
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

-- write the qml qrc file from the manifest, the qt.qrc rule compiles it later
function _add_qrcgen(target, cmds, setup, opt)
    local qrcfile = setup.paths.qrcfile
    cmds:show_progress(opt.progress, "${color.build.object}generating.qt.qml.qrc %s", path.filename(qrcfile))
    cmds:lua(_get_script("qrcgen.lua"), {qrcfile, setup.paths.manifestfile})
    cmds:add_depfiles(setup.depfiles)
    cmds:add_depvalues(setup.depvalues)
    cmds:set_depmtime(os.mtime(qrcfile))
    cmds:set_depcache(target:dependfile(qrcfile))
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
        end
    }
    if outdata and outdata ~= "" then
        os.mkdir(path.directory(scanfile))
        io.writefile(scanfile, outdata)
    end
end

-- add the import scan job of the given qml/js file, the result is the dependency graph of the module
function _add_scan(target, cmds, setup, file, opt)
    local scanfile = _get_scanfile(target, file.sourcefile)
    cmds:show_progress(opt.progress, "${color.build.object}scanning.qt.qml.imports %s", file.sourcefile)
    cmds:call(_scan_imports, {scanfile, setup.tools.importscanner, file.absfile, setup.importdirs})
    cmds:add_depfiles(file.absfile)
    cmds:add_depvalues(setup.tools.importscanner, setup.importdirs)
    cmds:set_depmtime(os.mtime(scanfile))
    cmds:set_depcache(target:dependfile(scanfile))
end

-- get the qmlcachegen/qmltc arguments shared by the tools
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
        if os.isfile(resource) then
            table.insert(args, "--resource")
            table.insert(args, resource)
        end
    end
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
    cmds:vrunv(setup.tools.cachegen, args)
    cmds:add_depfiles(_get_depfiles(target, setup, file))
    cmds:add_depvalues(setup.tools.cachegen, args)
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
    cmds:vrunv(setup.tools.cachegen, args)
    cmds:add_depfiles(setup.paths.loaderrsp)
    cmds:add_depvalues(setup.tools.cachegen, args)
    cmds:set_depmtime(os.mtime(cppfile))
    cmds:set_depcache(target:dependfile(cppfile))
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
    -- only qml components produce stats, e.g. a module with only .js files has none
    if #sidecars == 0 then
        for _, filepath in ipairs({setup.paths.aotstats, setup.paths.aotstatstxt, setup.paths.aotstatslist}) do
            if os.isfile(filepath) then
                cmds:rm(filepath)
            end
        end
        return
    end
    cmds:show_progress(opt.progress, "${color.build.object}generating.qt.qml.aotstats %s",
        path.filename(setup.paths.aotstats))
    cmds:lua(_get_script("aotstatsgen.lua"), table.join({setup.paths.aotstatslist}, sidecars))
    cmds:vrunv(setup.aot.tool, {"aggregate", setup.paths.aotstatslist, setup.paths.aotstats})
    cmds:vrunv(setup.aot.tool, {"format", setup.paths.aotstats, setup.paths.aotstatstxt})
    -- rebuild the report if any sidecar file has been regenerated
    cmds:add_depfiles(sidecars)
    cmds:add_depvalues(setup.aot.tool)
    local reportexists = os.isfile(setup.paths.aotstats) and os.isfile(setup.paths.aotstatstxt)
    cmds:set_depmtime(reportexists and os.mtime(setup.paths.aotstats) or 0)
    cmds:set_depcache(target:dependfile(setup.paths.aotstats))
end

-- generate the qmltc source of the given qml file
function _add_qmltc(target, cmds, setup, file, opt)
    local files = _get_qmltc_files(target, setup, file.sourcefile)
    local args = {"--bare", "--header", files.header, "--impl", files.impl, "--module", setup.setting.uri}
    -- qmltc puts the generated types into an anonymous namespace without a namespace,
    -- so components cannot include each other, use the module uri like Qt CMake does
    local namespace = setup.setting.namespace
    if namespace == "" then
        namespace = setup.setting.uri:gsub("%.", "::")
    end
    table.insert(args, "--namespace")
    table.insert(args, namespace)
    _add_import_args(args, setup)
    -- the file map is used by qmltc to include the headers of other components
    table.insert(args, "--resource")
    table.insert(args, setup.paths.qmltcmap)
    table.insert(args, file.absfile)
    cmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmltc %s", file.sourcefile)
    cmds:mkdir(path.directory(files.header))
    cmds:vrunv(setup.tools.qmltc, args)
    cmds:add_depfiles(_get_depfiles(target, setup, file))
    cmds:add_depfiles(setup.paths.qmltcmap)
    cmds:add_depvalues(setup.tools.qmltc, args)
    -- qmltc keeps the mtime of an unchanged output, so we track the last run by the depend file
    local dependfile = target:dependfile(files.header)
    local outputsexist = os.isfile(files.header) and os.isfile(files.impl)
    cmds:set_depmtime(outputsexist and os.mtime(dependfile) or 0)
    cmds:set_depcache(dependfile)
end

-- generate the moc source of the given qmltc header
function _add_qmltc_moc(target, cmds, setup, file, opt)
    local files = _get_qmltc_files(target, setup, file.sourcefile)
    local mocflags = table.join(utils.get_moc_flags(target), {
        "-I" .. path.unix(path.directory(files.header)), "-o", files.moc, files.header})
    cmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmltc.moc %s", file.sourcefile)
    cmds:vrunv(setup.tools.moc, mocflags)
    cmds:add_depfiles(files.header)
    cmds:add_depvalues(setup.tools.moc, mocflags)
    cmds:set_depmtime(os.mtime(files.moc))
    cmds:set_depcache(target:dependfile(files.moc))
end

-- add a generation job, the commands are skipped if the dependencies are not changed
function _add_job(jobgraph, name, target, run)
    jobgraph:add(name, function (index, total, opt)
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
function prepare(target, jobgraph, sourcebatch, opt)
    local setup = target:data("qt.qml.setup")
    if not setup then
        return
    end

    -- the generated c++ sources are compiled by the c++.build rule in the build phase
    _add_cppfiles(target, setup)

    local prefix = target:fullname() .. "/qt.qml"
    local qrcjob = prefix .. "/qrc"
    _add_job(jobgraph, qrcjob, target, function (cmds, jobopt)
        _add_qrcgen(target, cmds, setup, jobopt)
    end)

    -- the import scanner is only needed for the generated sources, qmltc only
    -- compiles the .qml files
    local scanfiles = {}
    if setup.need_cachegen then
        scanfiles = setup.qmls
    elseif setup.setting.type_compiler then
        for _, file in ipairs(setup.qmls) do
            if _is_qmltc_file(file.sourcefile) then
                table.insert(scanfiles, file)
            end
        end
    end
    local scangroup
    if #scanfiles > 0 then
        scangroup = prefix .. "/qmlimportscanner"
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
            for _, file in ipairs(setup.qmls) do
                _add_job(jobgraph, cachegengroup .. "/" .. file.sourcefile, target, function (cmds, jobopt)
                    _add_cachegen(target, cmds, setup, file, jobopt)
                end)
            end
            _add_job(jobgraph, cachegengroup .. "/loader", target, function (cmds, jobopt)
                _add_loader(target, cmds, setup, jobopt)
            end)
        end)
        -- qmlcachegen reads the qrc files and the scan output
        jobgraph:add_orders(qrcjob, cachegengroup)
        jobgraph:add_orders(scangroup, cachegengroup)
        if setup.aot.enabled then
            local aotstatsjob = prefix .. "/aotstats"
            _add_job(jobgraph, aotstatsjob, target, function (cmds, jobopt)
                _add_aotstats(target, cmds, setup, jobopt)
            end)
            jobgraph:add_orders(cachegengroup, aotstatsjob)
        end
    end

    if setup.setting.type_compiler then
        local qmltc_files = {}
        for _, file in ipairs(setup.qmls) do
            if _is_qmltc_file(file.sourcefile) then
                table.insert(qmltc_files, file)
            end
        end
        if #qmltc_files > 0 then
            local qmltcgroup = prefix .. "/qmltc"
            local mocgroup = prefix .. "/qmltc.moc"
            jobgraph:group(qmltcgroup, function ()
                for _, file in ipairs(qmltc_files) do
                    _add_job(jobgraph, qmltcgroup .. "/" .. file.sourcefile, target, function (cmds, jobopt)
                        _add_qmltc(target, cmds, setup, file, jobopt)
                    end)
                end
            end)
            jobgraph:group(mocgroup, function ()
                for _, file in ipairs(qmltc_files) do
                    _add_job(jobgraph, mocgroup .. "/" .. file.sourcefile, target, function (cmds, jobopt)
                        _add_qmltc_moc(target, cmds, setup, file, jobopt)
                    end)
                end
            end)
            -- qmltc reads the qrc files and the scan output, moc needs the qmltc headers
            jobgraph:add_orders(qrcjob, qmltcgroup)
            jobgraph:add_orders(scangroup, qmltcgroup)
            jobgraph:add_orders(qmltcgroup, mocgroup)
        end
    end
end
