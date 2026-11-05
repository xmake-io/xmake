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

-- imports
import("utils")
import("qrc")
import("cachegen")

-- create the module file entry of the given source file
function _new_file(target, setting, sourcefile)
    local alias, absfile = utils.get_alias(target, sourcefile)
    return {
        sourcefile    = sourcefile,
        absfile       = absfile,
        alias         = alias,
        resource_path = utils.get_prefix(setting.uri) .. alias
    }
end

-- collect the module files and their resource paths, keyed by source file
function _collect_files(target, setting, sourcefiles)
    local files = {}
    for _, sourcefile in ipairs(sourcefiles) do
        files[sourcefile] = _new_file(target, setting, sourcefile)
    end
    return files
end

-- write the module qrc
function _write_files(target, setup)
    local qrcdata = {
        prefix  = utils.get_prefix(setup.setting.uri),
        discard = setup.setting.discard and true or false,
        entries = {}
    }
    for _, file in ipairs(utils.get_file_list(setup.qmls)) do
        table.insert(qrcdata.entries, { alias = file.alias, path = file.absfile })
    end
    qrc.write_if_changed(setup.paths.qrcfile, qrcdata, target:is_rebuilt())
end

-- get the module setup shared by the prepare stages
--
-- The setup contains the complete module data, so it is created once and cached on
-- the target. The per-file prepare callback only reads it.
function _get_setup(target, sourcebatch)
    local setup = target:data("qt.qml.setup")
    if setup then
        return setup
    end
    local sourcefiles = sourcebatch and sourcebatch.sourcefiles or {}
    local setting = utils.get_setting(target)
    local tools = target:data("qt.qml.tools") or {}
    local paths = utils.get_paths(target)
    setup = {
        target        = target,
        setting       = setting,
        tools         = tools,
        paths         = paths,
        cachegenpaths = cachegen.get_paths(target),
        qmls          = _collect_files(target, setting, sourcefiles),
        importdirs    = table.join(target:data("qt").qmldir, setting.imports),
        need_cachegen = tools.cachegen ~= nil,
        resources     = { paths.qrcfile }
    }
    local resourcebatch = target:sourcebatches()["qt.qml.resource"]
    if resourcebatch and not table.empty(resourcebatch.sourcefiles) then
        -- the resource qrc is written by the qt.qml.resource before hook, which is
        -- ordered before the qt.qml hooks
        table.insert(setup.resources, paths.resourceqrc)
    end
    target:data_set("qt.qml.setup", setup)
    return setup
end

-- write the module qrc and generate the loader before the files are compiled
function before_prepare(target, batchcmds, sourcebatch, opt)
    local setup = _get_setup(target, sourcebatch)

    -- write the qrc synchronously, so it already exists when it is added to the target
    _write_files(target, setup)
    target:add("files", setup.paths.qrcfile)

    -- the loader lists the resource paths of all module files
    if setup.need_cachegen then
        cachegen.add_loader(batchcmds, setup, opt)
    end
end

-- prepare the given qml/js file with batchcmds
--
-- This is the default path, and it is also used when the commands are collected
-- instead of being run, e.g. by the project generators.
function on_preparecmd_file(target, batchcmds, sourcefile, opt)
    local setup = assert(target:data("qt.qml.setup"), "qt.qml: setup is not initialized")
    if setup.need_cachegen then
        local file = assert(setup.qmls[sourcefile], "qt.qml: unknown module file %s", sourcefile)
        cachegen.add_generate(batchcmds, setup, file, opt)
    end
end

-- register the generated sources after all files are generated
function after_prepare(target, _batchcmds, sourcebatch, _)
    local sourcefiles = sourcebatch.sourcefiles
    local setup = assert(target:data("qt.qml.setup"), "qt.qml: setup is not initialized")

    -- The generated files already exist at this point, so they can be added to the target
    -- without `always_added`; the c++ rule compiles them.
    if setup.need_cachegen then
        target:add("files", cachegen.get_generated_files(target, setup, sourcefiles))
    end
end
