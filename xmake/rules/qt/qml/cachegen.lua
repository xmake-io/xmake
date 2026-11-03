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
-- @file        cachegen.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.project.depend")
import("utils")
import("utils.progress", { alias = "progress_utils" })

-- get the qmlcachegen tool and check its capabilities
function get_tool(target, setting)
    local sdkver = semver.new(target:data("qt").sdkver)
    assert(sdkver:ge("6.2"), "qt.qml: qmlcachegen requires Qt >= 6.2, please disable it with {cachegen = false}")
    local tool = assert(utils.find_sdk_tool(target, "qmlcachegen"), "qt.qml: qmlcachegen is not found")
    if setting.only_bytecode then
        assert(
            utils.has_tool_option(tool, "--only-bytecode"),
            "qt.qml: qmlcachegen(%s) does not support --only-bytecode", tool.program
        )
    end
    return tool
end

-- get the generated c++ source of the given qml/js/mjs file
function get_output(target, sourcefile)
    return utils.get_autogen_file(target, "qmlcachegen", sourcefile, ".cpp")
end

-- get the generated files of the module
function get_generated_files(target, setup, sourcefiles)
    local files = {}
    for _, sourcefile in ipairs(sourcefiles) do
        table.insert(files, get_output(target, sourcefile))
    end
    table.insert(files, setup.cachegenpaths.loadercpp)
    return files
end

-- get the generated files and directories of qmlcachegen
function get_paths(target)
    local dir = utils.get_autogen_dir(target, "qmlcachegen")
    return { loadercpp = path.join(dir, target:name() .. "_qmlcache_loader.cpp") }
end

-- get the qmlcachegen arguments of the given qml/js/mjs file
function get_args(setup, file)
    local args = { "--bare", "--resource-path", file.resource_path, "-o", get_output(setup.target, file.sourcefile) }
    utils.add_import_args(args, setup)
    if setup.setting.only_bytecode then
        table.insert(args, "--only-bytecode")
    end
    table.insert(args, file.absfile)
    return args
end

-- get the dependency files of the given qml/js/mjs file
--
-- qmlcachegen reads the qrc files with `--resource`, so every output depends on
-- them. Adding or removing a module file regenerates all outputs, while editing
-- one file only regenerates its output, matching Qt CMake's granularity. With
-- type_compiler, the generated qmldir is passed with `-i` and is also a dependency.
function get_depfiles(setup, file)
    local depfiles = { file.absfile }
    table.join2(depfiles, setup.resources)
    if setup.need_qmltc then
        table.insert(depfiles, setup.qmltcpaths.qmldir)
    end
    return depfiles
end

-- add the generation commands of the given qml/js/mjs file to batchcmds
function generate_cmd(batchcmds, setup, file, opt)
    local cppfile = get_output(setup.target, file.sourcefile)
    local args = get_args(setup, file)
    batchcmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmlcachegen %s", file.sourcefile)
    batchcmds:mkdir(path.directory(cppfile))
    batchcmds:vrunv(setup.tools.cachegen.program, args)
    batchcmds:add_depfiles(get_depfiles(setup, file))
    batchcmds:add_depvalues(setup.tools.cachegen.program, args)
    batchcmds:set_depmtime(os.mtime(cppfile))
    batchcmds:set_depcache(setup.target:dependfile(cppfile))
    return cppfile
end

-- generate the c++ source of the given qml/js/mjs file directly
--
-- This is used by the jobgraph mode, where no batchcmds is created for every file.
function generate(setup, file, opt)
    local target = setup.target
    local cppfile = get_output(target, file.sourcefile)
    local args = get_args(setup, file)
    local dryrun = option.get("dry-run")
    depend.on_changed(function ()
        progress_utils.show(opt.progress, "${color.build.object}generating.qt.qmlcachegen %s", file.sourcefile)
        -- `depend.on_changed()` with dryrun still calls the callback and only skips
        -- saving the dependency state, so the command itself must be skipped here
        if not dryrun then
            os.mkdir(path.directory(cppfile))
            os.vrunv(setup.tools.cachegen.program, args)
        end
    end, {
        dependfile = target:dependfile(cppfile),
        files      = get_depfiles(setup, file),
        values     = { setup.tools.cachegen.program, args },
        lastmtime  = os.mtime(cppfile),
        changed    = target:is_rebuilt(),
        dryrun     = dryrun
    })
    return cppfile
end

-- generate the qmlcache_loader
function add_loader(batchcmds, setup, opt)
    local cppfile = setup.cachegenpaths.loadercpp
    local args = { "--resource-name", "qmlcache_" .. setup.target:name(), "-o", cppfile }
    for _, resource in ipairs(setup.resources) do
        table.join2(args, { "--resource", resource })
    end
    for _, file in ipairs(utils.get_file_list(setup.qmls)) do
        table.insert(args, file.resource_path)
    end
    -- qmlcachegen reads the argument file line by line, so we must keep the raw arguments.
    local depvalues = table.clone(args)
    if is_host("windows") then
        args = winos.cmdargv(args, { raw = true })
    end
    batchcmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmlcachegen %s", path.filename(cppfile))
    batchcmds:mkdir(path.directory(cppfile))
    batchcmds:vrunv(setup.tools.cachegen.program, args)
    -- the qrc files are the inputs of the loader, they are only rewritten when the
    -- module file list is changed, the resource paths themselves are tracked as
    -- the depvalues of the command
    batchcmds:add_depfiles(setup.resources)
    batchcmds:add_depvalues(setup.tools.cachegen.program, depvalues)
    batchcmds:set_depmtime(os.mtime(cppfile))
    batchcmds:set_depcache(setup.target:dependfile(cppfile))
end
