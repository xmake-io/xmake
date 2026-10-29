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
-- @file        qrc.lua
--

-- imports
import("core.base.xml")

-- create the <file> node of the given qrc entry
function _new_file_node(alias, filepath, empty)
    local attrs = {alias = alias}
    if empty then
        attrs.empty = "true"
    end
    return xml.new({name = "file", attrs = attrs, children = {xml.text(filepath)}})
end

-- generate the qrc file of the QML module
--
-- The qrc file is an XML document, so we build a node tree and let the xml module
-- escape the paths and generate the text, e.g. a path containing `&` or `<` would
-- break the qrc otherwise. The xml module also sorts the attributes, so the same
-- input always gives the same qrc and write_if_changed() can skip unchanged files.
-- The two-space indent keeps the output identical to the previous hand-written
-- layout, so existing qrc files are not rewritten after this change.
function generate_qrc(qrcdata)
    local prefix = qrcdata.prefix
    local entries = qrcdata.entries or {}
    local resources = {}
    if #entries > 0 then
        local files = {}
        for _, entry in ipairs(entries) do
            table.insert(files, _new_file_node(entry.alias, entry.path, qrcdata.discard))
        end
        table.insert(resources, xml.new({
            name     = "qresource",
            attrs    = prefix and {prefix = prefix} or nil,
            children = files
        }))
    end
    -- the qmldir must be available at :/qt/qml/<uri>/qmldir
    if qrcdata.qmldir then
        assert(prefix, "qrc: the qml module prefix is required for the qmldir file!")
        table.insert(resources, xml.new({
            name     = "qresource",
            attrs    = {prefix = prefix:gsub("/$", "")},
            children = {_new_file_node("qmldir", qrcdata.qmldir)}
        }))
    end
    local doc = xml.new({name = "RCC", children = resources})
    return assert(xml.encode(doc, {pretty = true, indent = 2})) .. "\n"
end

-- write the file only if its content is changed
function write_if_changed(filepath, content)
    if os.isfile(filepath) and io.readfile(filepath) == content then
        return false
    end
    os.mkdir(path.directory(filepath))
    io.writefile(filepath, content)
    return true
end
