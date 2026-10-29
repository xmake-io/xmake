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

-- escape the given text for xml
function _escape(str)
    return (tostring(str):gsub("[&<>\"']", {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["\""] = "&quot;",
        ["'"] = "&apos;"
    }))
end

-- render the qrc file of the QML module
function render_qrc(qrcdata)
    local lines = {"<RCC>"}
    local prefix = qrcdata.prefix
    local entries = qrcdata.entries or {}
    if #entries > 0 then
        if prefix then
            table.insert(lines, string.format("  <qresource prefix=\"%s\">", _escape(prefix)))
        else
            table.insert(lines, "  <qresource>")
        end
        for _, entry in ipairs(entries) do
            local empty = qrcdata.discard and " empty=\"true\"" or ""
            table.insert(lines, string.format("    <file alias=\"%s\"%s>%s</file>",
                _escape(entry.alias), empty, _escape(entry.path)))
        end
        table.insert(lines, "  </qresource>")
    end
    -- the qmldir must be available at :/qt/qml/<uri>/qmldir
    if qrcdata.qmldir then
        assert(prefix, "qrc: the qml module prefix is required for the qmldir file!")
        table.insert(lines, string.format("  <qresource prefix=\"%s\">", _escape(prefix:gsub("/$", ""))))
        table.insert(lines, string.format("    <file alias=\"qmldir\">%s</file>", _escape(qrcdata.qmldir)))
        table.insert(lines, "  </qresource>")
    end
    table.insert(lines, "</RCC>")
    return table.concat(lines, "\n") .. "\n"
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
