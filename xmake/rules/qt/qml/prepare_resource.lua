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
-- @file        prepare_resource.lua
--

-- imports
import("core.base.option")
import("utils")
import("qrc")

-- The resource qrc is generated while the prepare job graph is being built,
-- so the qmlcachegen/qmltc jobs of qt.qml, which read it with `--resource`,
-- always see the final file. `jobgraph` is unused here.
function main(target, jobgraph, sourcebatch, opt)
    -- keep the generated qrc deterministic
    local sourcefiles = table.unique(sourcebatch.sourcefiles)
    table.sort(sourcefiles)
    if #sourcefiles == 0 then
        return
    end
    assert(
        target:data("qt.rcc"), [[qt.qml.resource: rcc not found, please add_rules("qt.qrc") to target(%s)]],
        target:name()
    )

    local setting = utils.get_setting(target)
    local qrcdata = { prefix = utils.get_prefix(setting.uri), entries = {} }
    for _, sourcefile in ipairs(sourcefiles) do
        local alias, absfile = utils.get_alias(target, sourcefile)
        table.insert(qrcdata.entries, { alias = alias, path = absfile })
    end
    local paths = utils.get_paths(target)
    -- the dry run does not generate anything, see prepare_qml.lua
    if not option.get("dry-run") then
        qrc.write_if_changed(paths.resourceqrc, qrc.render_qrc(qrcdata))
        target:add("files", paths.resourceqrc, { always_added = true })
    end
end
