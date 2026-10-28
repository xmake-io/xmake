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
-- @file        config.lua
--

-- imports
import("core.base.json")
import("utils")
import("qrc")

-- is the given file a qmldir file?
function _is_qmldir(file)
    local filename = path.filename(file):lower()
    return filename == "qmldir" or path.extension(filename) == ".qmldir"
end

-- get the source files bound to the given rule
function _get_sourcefiles(target, rulename)
    local sourcebatch = target:sourcebatches()[rulename]
    return sourcebatch and sourcebatch.sourcefiles or {}
end

-- collect the qml files and the qmldir files of the module
function _collect_files(target, setting)
    local qmls = {}
    local qmldirs = {}
    for _, file in ipairs(_get_sourcefiles(target, "qt.qml")) do
        local alias, absfile = utils.get_alias(target, file)
        if _is_qmldir(file) then
            table.insert(qmldirs, {sourcefile = file, absfile = absfile})
        else
            table.insert(qmls, {
                sourcefile    = file,
                absfile       = absfile,
                alias         = alias,
                resource_path = utils.get_resource_path(setting.uri, alias)
            })
        end
    end
    if #qmldirs > 1 then
        wprint("qt.qml: multiple qmldir files are found in target(%s), only '%s' is packaged, " ..
            "all of them are used for imports", target:name(), qmldirs[1].sourcefile)
    end
    return qmls, qmldirs
end

-- check the tools and the version requirements
function _check_tools(target, setting, need_cachegen, need_importscanner)
    local sdkver = utils.get_sdkver(target)
    local tools = {}
    if need_cachegen then
        assert(sdkver:ge("6.2"),
            "qt.qml: qmlcachegen requires Qt >= 6.2, please disable it with {cachegen = false}")
    end
    if setting.type_compiler then
        assert(sdkver:ge("6.4"), "qt.qml: qmltc requires Qt >= 6.4, please disable it with {type_compiler = false}")
    end
    if need_cachegen then
        tools.cachegen = assert(utils.find_tool(target, "qmlcachegen"),
            "qt.qml: qmlcachegen not found in the Qt SDK(%s)!", table.concat(utils.get_tool_dirs(target), ", "))
        utils.check_tool_version(target, tools.cachegen, "qmlcachegen")
        if setting.only_bytecode then
            assert(utils.has_tool_option(target, tools.cachegen, "--only-bytecode"),
                "qt.qml: qmlcachegen(%s) does not support --only-bytecode!", tools.cachegen)
        end
    end
    if setting.type_compiler then
        tools.qmltc = assert(utils.find_tool(target, "qmltc"),
            "qt.qml: qmltc not found in the Qt SDK(%s)!", table.concat(utils.get_tool_dirs(target), ", "))
        utils.check_tool_version(target, tools.qmltc, "qmltc")
        tools.moc = target:data("qt.moc") or utils.find_tool(target, "moc")
        assert(tools.moc and os.isexec(tools.moc), "qt.qml: moc not found!")
        utils.check_tool_version(target, tools.moc, "moc")
    end
    if need_importscanner then
        -- the import scanner provides the dependency graph of the module
        tools.importscanner = assert(utils.find_tool(target, "qmlimportscanner"),
            "qt.qml: qmlimportscanner not found in the Qt SDK(%s)!", table.concat(utils.get_tool_dirs(target), ", "))
    end
    return tools
end

-- resolve the aot stats settings
function _resolve_aotstats(target, setting, tools, need_cachegen)
    local aot = {enabled = false}
    if need_cachegen and not setting.only_bytecode then
        aot.tool = utils.find_tool(target, "qmlaotstats")
        local supported = tools.cachegen and utils.has_tool_option(target, tools.cachegen, "--dump-aot-stats")
        if setting.aot_stats == true then
            assert(aot.tool, "qt.qml: qt.qml.aot_stats is enabled, but qmlaotstats is not found " ..
                "(requires Qt >= 6.8), please disable it with {aot_stats = false}")
            assert(supported, "qt.qml: qmlcachegen(%s) does not support --dump-aot-stats!", tools.cachegen)
            aot.enabled = true
        elseif setting.aot_stats == nil then
            aot.enabled = supported and aot.tool ~= nil
        end
    elseif setting.aot_stats == true then
        wprint("qt.qml: qt.qml.aot_stats is ignored because the AOT compilation is disabled")
    end
    return aot
end

-- get the generated directories and files
function _get_paths(target)
    local autogendir = path.absolute(target:autogendir())
    local qmldir = path.join(autogendir, "rules", "qt", "qml")
    local cachegendir = path.join(autogendir, "rules", "qt", "qmlcachegen")
    return {
        qmldir       = qmldir,
        manifestfile = path.join(qmldir, "qml.manifest"),
        qrcfile      = path.join(qmldir, "qml_module.qrc"),
        resourceqrc  = path.join(qmldir, "qml_resource.qrc"),
        cachegendir  = cachegendir,
        loaderrsp    = path.join(cachegendir, target:name() .. "_qml_loader_file_list.rsp"),
        loadercpp    = path.join(cachegendir, target:name() .. "_qmlcache_loader.cpp"),
        aotstats     = path.join(cachegendir, target:name() .. ".aotstats"),
        aotstatstxt  = path.join(cachegendir, target:name() .. ".aotstats.txt"),
        aotstatslist = path.join(cachegendir, target:name() .. ".aotstatslist"),
        qmltc        = path.join(autogendir, "rules", "qt", "qmltc"),
        qmltcmap     = path.join(autogendir, "rules", "qt", "qmltc", "qmltc_file_map.qrc")
    }
end

-- write the manifest and the bootstrap qrc
function _write_qml_files(target, paths, setting, qmls, qmldirs)
    local manifest = {
        prefix  = utils.get_prefix(setting.uri),
        discard = setting.discard and true or false,
        qmldir  = qmldirs[1] and qmldirs[1].absfile or nil,
        entries = json.mark_as_array({})
    }
    for _, file in ipairs(qmls) do
        table.insert(manifest.entries, {alias = file.alias, path = file.absfile})
    end
    qrc.write_if_changed(paths.manifestfile, qrc.render_manifest(manifest))
    qrc.write_if_changed(paths.qrcfile, qrc.render_qrc(manifest))
    return manifest
end

-- write the file list for the qmlcache_loader
function _write_loader_rsp(target, paths, qmls, has_resources)
    local rsp = {}
    table.insert(rsp, "--resource")
    table.insert(rsp, paths.qrcfile)
    if has_resources then
        table.insert(rsp, "--resource")
        table.insert(rsp, paths.resourceqrc)
    end
    for _, file in ipairs(qmls) do
        table.insert(rsp, file.resource_path)
    end
    qrc.write_if_changed(paths.loaderrsp, table.concat(rsp, "\n") .. "\n")
end

-- write the qml file mapping used by qmltc to include the headers of other components
function _write_qmltc_map(target, paths, qmls)
    local manifest = {entries = {}}
    for _, file in ipairs(qmls) do
        if path.extension(file.sourcefile):lower() == ".qml" then
            table.insert(manifest.entries, {alias = utils.get_qmltc_name(target, file.sourcefile) .. ".h",
                path = file.absfile})
        end
    end
    qrc.write_if_changed(paths.qmltcmap, qrc.render_qrc(manifest))
end

function main(target)
    local qmlfiles = _get_sourcefiles(target, "qt.qml")
    if #qmlfiles == 0 then
        return
    end

    local setting = utils.get_setting(target)
    local qmls, qmldirs = _collect_files(target, setting)
    local has_resources = #_get_sourcefiles(target, "qt.qml.resource") > 0
    local need_cachegen = setting.cachegen and #qmls > 0
    local has_qmls = false
    for _, file in ipairs(qmls) do
        if path.extension(file.sourcefile):lower() == ".qml" then
            has_qmls = true
            break
        end
    end
    local need_importscanner = need_cachegen or (setting.type_compiler and has_qmls)

    -- check the tools and version requirements
    local tools = _check_tools(target, setting, need_cachegen, need_importscanner)
    local aot = _resolve_aotstats(target, setting, tools, need_cachegen)

    local paths = _get_paths(target)
    local manifest = _write_qml_files(target, paths, setting, qmls, qmldirs)
    if need_cachegen then
        _write_loader_rsp(target, paths, qmls, has_resources)
    end

    if setting.type_compiler and #qmls > 0 then
        _write_qmltc_map(target, paths, qmls)
        -- qmltc generated headers are included by the generated sources
        target:add("includedirs", paths.qmltc)
    end

    -- compile the qml qrc with the qt.qrc rule
    target:add("files", paths.qrcfile, {rules = {"qt.qrc", override = true}})

    -- save the settings for the build script
    local importdirs = {}
    if target:data("qt").qmldir then
        table.insert(importdirs, target:data("qt").qmldir)
    end
    table.join2(importdirs, setting.imports)
    local resources = {paths.qrcfile}
    if has_resources then
        table.insert(resources, paths.resourceqrc)
    end
    local entrykeys = {}
    for _, entry in ipairs(manifest.entries) do
        table.insert(entrykeys, entry.alias .. "=" .. entry.path)
    end
    local depvalues = {
        "uri=" .. setting.uri,
        "discard=" .. tostring(setting.discard),
        "only_bytecode=" .. tostring(setting.only_bytecode),
        "type_compiler=" .. tostring(setting.type_compiler),
        "namespace=" .. setting.namespace,
        "aot=" .. tostring(aot.enabled),
        "qmldir=" .. tostring(manifest.qmldir),
        "entries=" .. hash.strhash32(table.concat(entrykeys, "|")),
        "imports=" .. table.concat(setting.imports, "|"),
        "cachegen=" .. tostring(tools.cachegen),
        "qmltc=" .. tostring(tools.qmltc),
        "moc=" .. tostring(tools.moc),
        "aotstats=" .. tostring(aot.tool)
    }
    local depfiles = {paths.manifestfile}
    if need_cachegen then
        table.insert(depfiles, paths.loaderrsp)
    end
    for _, file in ipairs(qmls) do
        table.insert(depfiles, file.absfile)
    end
    for _, qmldir in ipairs(qmldirs) do
        table.insert(depfiles, qmldir.absfile)
    end
    target:data_set("qt.qml.setup", {
        setting     = setting,
        module_id   = setting.uri .. "(" .. target:name() .. ")",
        paths       = paths,
        qmls        = qmls,
        qmldirs     = qmldirs,
        importdirs  = importdirs,
        resources   = resources,
        tools       = tools,
        aot         = aot,
        need_cachegen = need_cachegen,
        depfiles    = depfiles,
        depvalues   = depvalues
    })
end
