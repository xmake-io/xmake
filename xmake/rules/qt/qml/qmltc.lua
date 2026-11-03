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
-- @file        qmltc.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.project.depend")
import("utils")
import("utils.progress", { alias = "progress_utils" })
import("qrc")

-- get the qmltc tool and check the SDK version
function get_tool(target)
    local sdkver = semver.new(target:data("qt").sdkver)
    assert(sdkver:ge("6.4"), "qt.qml: qmltc requires Qt >= 6.4, please disable it with {type_compiler = false}")
    return assert(utils.find_sdk_tool(target, "qmltc"), "qt.qml: qmltc is not found")
end

-- get the qmldir type version, e.g. 2.3.4 -> 2.3
function get_qmldir_version(setting)
    local version = semver.new(setting.version)
    return string.format("%d.%d", version:major(), version:minor())
end

-- get the generated files of the given qml file
--
-- qmltc includes the generated headers by their file name only, so the paths are
-- flattened and hashed to avoid collisions between different source directories.
function get_outputs(setup, sourcefile)
    return {
        header = utils.get_autogen_file(setup.target, "qmltc", sourcefile, ".h", { flat = true }),
        impl   = utils.get_autogen_file(setup.target, "qmltc", sourcefile, ".cpp", { flat = true })
    }
end

-- get the generated files and directories of qmltc
function get_paths(target)
    local gendir = utils.get_autogen_dir(target, "qml")
    local qmltcdir = utils.get_autogen_dir(target, "qmltc")
    return {
        qmltcdir = qmltcdir,
        qmltcmap = path.join(qmltcdir, "qmltc_file_map.qrc"),
        -- qmltc resolves the types of the module through the qmldir passed with `-i`,
        -- the file is only a build-time input and points to the source files
        qmldir = path.join(qmltcdir, "qmldir"),
        -- the qmldir packed into the module qrc, its type entries use the resource aliases
        resourceqmldir = path.join(gendir, "qmldir")
    }
end

-- get the qmldir type entry of the given module file, only the upper-case file
-- names are QML types, the lower-case files are plain QML documents, matching
-- qt6_target_qml_sources() in Qt6QmlMacros.cmake
--
-- qmldir splits the entry by whitespace, so a path containing spaces must be
-- quoted, otherwise qmltc reports "a component declaration requires two or three
-- arguments" or silently resolves the type as a C++ type.
function _get_qmldir_entry(file, version, filepath)
    local typename = utils.is_qmltc_file(file.sourcefile) and path.basename(file.sourcefile)
    if typename and typename:match("^[A-Z]") then
        if filepath:find("%s") then
            filepath = '"' .. filepath .. '"'
        end
        return string.format("%s %s %s", typename, version, filepath)
    end
end

-- write the qmldir only if its content is changed
--
-- The lines are the dependency values, so adding or removing a type, or changing the
-- module version, rewrites the qmldir without touching it on an unchanged build.
function _write_qmldir(filepath, lines, is_rebuilt)
    depend.on_changed(function ()
        os.mkdir(path.directory(filepath))
        io.writefile(filepath, table.concat(lines, "\n") .. "\n")
    end, {
        dependfile = filepath .. ".d",
        files      = filepath,
        values     = lines,
        lastmtime  = os.mtime(filepath),
        changed    = is_rebuilt
    })
end

-- write the qmldir used by qmltc
--
-- qmltc resolves the types of the module through the qmldir passed with `-i`, see
-- _qt_internal_target_enable_qmltc() in Qt6QmlMacros.cmake. Qt CMake copies the QML
-- files into the module output directory and writes the qmldir next to them, while
-- xmake keeps the sources in place, so the type entries use paths relative to the
-- qmldir.
function _write_qmltc_qmldir(setup, is_rebuilt)
    local lines = { "module " .. setup.setting.uri }
    for _, file in ipairs(utils.get_file_list(setup.qmls)) do
        local relpath = path.unix(path.relative(file.absfile, setup.qmltcpaths.qmltcdir))
        local entry = _get_qmldir_entry(file, setup.qmldir_version, relpath)
        if entry then
            table.insert(lines, entry)
        end
    end
    _write_qmldir(setup.qmltcpaths.qmldir, lines, is_rebuilt)
end

-- write the qmldir packed into the module qrc
--
-- qmltc compiles `import <uri>` against the build-time qmldir, but the generated code
-- still loads the QML module at run time (QQmlEnginePrivate::compilationUnitFromUrl),
-- so the qrc needs a qmldir. Otherwise the engine reports `module "<uri>" is not
-- installed` and the generated QML_init() crashes. The type entries use the resource
-- aliases, e.g. `MyButton 2.3 MyButton.qml`.
function _write_resource_qmldir(setup, is_rebuilt)
    local lines = { "module " .. setup.setting.uri, "prefer :" .. utils.get_prefix(setup.setting.uri) }
    for _, file in ipairs(utils.get_file_list(setup.qmls)) do
        local entry = _get_qmldir_entry(file, setup.qmldir_version, path.unix(file.alias))
        if entry then
            table.insert(lines, entry)
        end
    end
    _write_qmldir(setup.qmltcpaths.resourceqmldir, lines, is_rebuilt)
end

-- write the qmltc file map, the build-time qmldir and the runtime qmldir
function write_files(setup, is_rebuilt)
    -- qmltc uses the file map to include the headers of the other components
    local mapdata = { entries = {} }
    for _, file in ipairs(utils.get_file_list(setup.qmls)) do
        if utils.is_qmltc_file(file.sourcefile) then
            table.insert(mapdata.entries, {
                alias = path.filename(get_outputs(setup, file.sourcefile).header),
                path  = file.absfile
            })
        end
    end
    qrc.write_if_changed(setup.qmltcpaths.qmltcmap, mapdata, is_rebuilt)
    _write_qmltc_qmldir(setup, is_rebuilt)
    _write_resource_qmldir(setup, is_rebuilt)
end

-- get the qmltc arguments of the given qml file
function get_args(setup, file)
    local files = get_outputs(setup, file.sourcefile)
    -- the file map is used by qmltc to include the headers of other components,
    -- the generated qmldir is passed by utils.add_import_args()
    local args = {
        "--bare", "--header", files.header, "--impl", files.impl, "--module", setup.setting.uri, "--resource",
        setup.qmltcpaths.qmltcmap
    }
    local namespace = setup.setting.namespace
    if namespace == nil then
        -- qmltc puts the generated types into an anonymous namespace by default and
        -- then components cannot include each other, use the module uri like Qt CMake does
        namespace = setup.setting.uri:gsub("%.", "::")
    end
    -- an empty namespace disables `--namespace`, e.g. to keep the anonymous namespace
    if namespace ~= "" then
        table.join2(args, { "--namespace", namespace })
    end
    utils.add_import_args(args, setup)
    table.insert(args, file.absfile)
    return args
end

-- get the dependency files of the given qml file
--
-- The file map and qmldir describe the types of the module, and the qrc files are
-- passed with `--resource`, so all of them are inputs of every qmltc invocation.
function get_depfiles(setup, file)
    local depfiles = { file.absfile, setup.qmltcpaths.qmldir, setup.qmltcpaths.qmltcmap }
    table.join2(depfiles, setup.resources)
    return depfiles
end

-- add the generation commands of the given qml file to batchcmds
function generate_cmd(batchcmds, setup, file, opt)
    local files = get_outputs(setup, file.sourcefile)
    local args = get_args(setup, file)
    local dependfile = setup.target:dependfile(files.header)
    batchcmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmltc %s", file.sourcefile)
    batchcmds:mkdir(path.directory(files.header))
    batchcmds:vrunv(setup.tools.qmltc.program, args)
    batchcmds:add_depfiles(get_depfiles(setup, file))
    batchcmds:add_depvalues(setup.tools.qmltc.program, args)
    batchcmds:set_depmtime(os.mtime(dependfile))
    batchcmds:set_depcache(dependfile)
    return files
end

-- generate the qmltc source of the given qml file directly
--
-- This is used by the jobgraph mode, where no batchcmds is created for every file.
function generate(setup, file, opt)
    local target = setup.target
    local files = get_outputs(setup, file.sourcefile)
    local args = get_args(setup, file)
    local dependfile = target:dependfile(files.header)
    local dryrun = option.get("dry-run")
    depend.on_changed(function ()
        progress_utils.show(opt.progress, "${color.build.object}generating.qt.qmltc %s", file.sourcefile)
        -- `depend.on_changed()` with dryrun still calls the callback and only skips
        -- saving the dependency state, so the command itself must be skipped here
        if not dryrun then
            os.mkdir(path.directory(files.header))
            os.vrunv(setup.tools.qmltc.program, args)
        end
    end, {
        dependfile = dependfile,
        files      = get_depfiles(setup, file),
        values     = { setup.tools.qmltc.program, args },
        lastmtime  = os.mtime(dependfile),
        changed    = target:is_rebuilt(),
        dryrun     = dryrun
    })
    return files
end

-- get the generated sources and headers of the module
function get_generated_files(setup, sourcefiles)
    local cppfiles = {}
    local headers = {}
    for _, sourcefile in ipairs(sourcefiles) do
        if utils.is_qmltc_file(sourcefile) then
            local files = get_outputs(setup, sourcefile)
            table.insert(cppfiles, files.impl)
            table.insert(headers, files.header)
        end
    end
    return { cppfiles = cppfiles, headers = headers }
end
