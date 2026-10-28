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
-- @file        resource.lua
--

-- imports
import("utils")
import("qrc")

-- ensure the qt sdk data, the rule can be used without qt.qml
function _ensure_qt(target)
    local qt = target:data("qt")
    if not qt then
        import("detect.sdks.find_qt")
        qt = assert(find_qt(nil, {verbose = true}), "Qt SDK not found!")
        target:data_set("qt", qt)
    end
    return qt
end

-- generate the qrc file of the module resources
function main(target, sourcebatch, opt)
    local sourcefiles = sourcebatch.sourcefiles
    if #sourcefiles == 0 then
        return
    end
    _ensure_qt(target)
    assert(utils.find_rcc(target), "rcc not found!")

    local setting = utils.get_setting(target)
    local manifest = {prefix = utils.get_prefix(setting.uri), entries = {}}
    for _, file in ipairs(sourcefiles) do
        local alias, absfile = utils.get_alias(target, file)
        table.insert(manifest.entries, {alias = alias, path = absfile})
    end
    local qrcfile = path.join(path.absolute(target:autogendir()), "rules", "qt", "qml", "qml_resource.qrc")
    qrc.write_if_changed(qrcfile, qrc.render_qrc(manifest))

    -- compile the resource qrc with the qt.qrc rule
    target:add("files", qrcfile, {rules = {"qt.qrc", override = true}})
    target:data_set("qt.qml.resource.qrc", qrcfile)
end
