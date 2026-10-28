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
import("utils")

-- add the object file of the given generated c++ source file
function _add_objectfile(target, batchcmds, sourcefile)
    local objectfile = target:objectfile(sourcefile)
    table.insert(target:objectfiles(), objectfile)
    batchcmds:compile(sourcefile, objectfile)
end

-- generate the qml qrc from the manifest, it runs before the qt.qrc rule
function _add_qrcgen(target, batchcmds, setup, opt)
    local qrcfile = setup.paths.qrcfile
    batchcmds:show_progress(opt.progress, "${color.build.object}generating.qt.qml.qrc %s", path.filename(qrcfile))
    batchcmds:mkdir(path.directory(qrcfile))
    batchcmds:lua(path.join(os.programdir(), "rules", "qt", "qml", "qrcgen.lua"),
        {qrcfile, setup.paths.manifestfile})
    batchcmds:add_depfiles(setup.depfiles)
    batchcmds:add_depvalues(setup.depvalues)
    batchcmds:set_depmtime(os.mtime(qrcfile))
    batchcmds:set_depcache(target:dependfile(qrcfile))
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

-- compile the given qml/js/mjs file to c++
function _add_cachegen(target, batchcmds, setup, file, opt)
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
    batchcmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmlcachegen %s", file.sourcefile)
    batchcmds:mkdir(path.directory(cppfile))
    batchcmds:vrunv(setup.tools.cachegen, args)
    _add_objectfile(target, batchcmds, cppfile)
end

-- generate and compile the qmlcache_loader
function _add_loader(target, batchcmds, setup, opt)
    local cppfile = setup.paths.loadercpp
    batchcmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmlcachegen %s", path.filename(cppfile))
    batchcmds:mkdir(path.directory(cppfile))
    batchcmds:vrunv(setup.tools.cachegen, {"--resource-name", "qmlcache_" .. target:name(),
        "-o", cppfile, "@" .. setup.paths.loaderrsp})
    _add_objectfile(target, batchcmds, cppfile)
end

-- aggregate and format the aot compilation statistics
function _add_aotstats(target, batchcmds, setup, opt)
    local sidecars = {}
    for _, file in ipairs(setup.qmls) do
        table.insert(sidecars, utils.get_autogen_file(target, "qmlcachegen", file.sourcefile, ".cpp") .. ".aotstats")
    end
    batchcmds:show_progress(opt.progress, "${color.build.object}generating.qt.qml.aotstats %s",
        path.filename(setup.paths.aotstats))
    batchcmds:mkdir(path.directory(setup.paths.aotstats))
    batchcmds:lua(path.join(os.programdir(), "rules", "qt", "qml", "aotstatsgen.lua"),
        table.join({setup.paths.aotstatslist}, sidecars))
    batchcmds:vrunv(setup.aot.tool, {"aggregate", setup.paths.aotstatslist, setup.paths.aotstats})
    batchcmds:vrunv(setup.aot.tool, {"format", setup.paths.aotstats, setup.paths.aotstatstxt})
end

-- generate the qmltc source file of the given qml file
function _add_qmltc(target, batchcmds, setup, file, opt)
    local name = utils.get_qmltc_name(target, file.sourcefile)
    local header = path.join(setup.paths.qmltc, name .. ".h")
    local impl = path.join(setup.paths.qmltc, name .. ".cpp")
    local args = {"--bare", "--header", header, "--impl", impl, "--module", setup.setting.uri}
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
    batchcmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmltc %s", file.sourcefile)
    batchcmds:mkdir(path.directory(header))
    batchcmds:vrunv(setup.tools.qmltc, args)
end

-- compile the qmltc source file and its moc source
function _add_qmltc_compile(target, batchcmds, setup, file, opt)
    local name = utils.get_qmltc_name(target, file.sourcefile)
    local header = path.join(setup.paths.qmltc, name .. ".h")
    local impl = path.join(setup.paths.qmltc, name .. ".cpp")
    local mocfile = path.join(setup.paths.qmltc, "moc_" .. name .. ".cpp")
    -- the generated header contains Q_OBJECT and must be processed by moc
    local mocflags = table.join(utils.get_moc_flags(target), {
        "-I" .. path.unix(path.directory(header)), "-o", mocfile, header})
    batchcmds:vrunv(setup.tools.moc, mocflags)
    _add_objectfile(target, batchcmds, impl)
    _add_objectfile(target, batchcmds, mocfile)
end

function main(target, batchcmds, sourcebatch, opt)
    local setup = target:data("qt.qml.setup")
    if not setup then
        return
    end

    -- regenerate the qml qrc before the qt.qrc rule compiles it
    _add_qrcgen(target, batchcmds, setup, opt)

    if setup.need_cachegen then
        for _, file in ipairs(setup.qmls) do
            _add_cachegen(target, batchcmds, setup, file, opt)
        end
        _add_loader(target, batchcmds, setup, opt)
        if setup.aot.enabled then
            _add_aotstats(target, batchcmds, setup, opt)
        end
    end

    if setup.setting.type_compiler then
        -- generate all headers first, one component may include the headers of other components
        for _, file in ipairs(setup.qmls) do
            if path.extension(file.sourcefile):lower() == ".qml" then
                _add_qmltc(target, batchcmds, setup, file, opt)
            end
        end
        for _, file in ipairs(setup.qmls) do
            if path.extension(file.sourcefile):lower() == ".qml" then
                _add_qmltc_compile(target, batchcmds, setup, file, opt)
            end
        end
    end
end
