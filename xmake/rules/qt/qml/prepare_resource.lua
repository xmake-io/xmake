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
import("utils")
import("qrc")

-- The resource qrc is generated synchronously in the before prepare stage, so the
-- qt.qml on prepare jobs, which read it with `--resource`, always see the final file.
function main(target, _batchcmds, sourcebatch, _)
    local sourcefiles = sourcebatch.sourcefiles
    local setting = utils.get_setting(target)
    local qrcdata = { prefix = utils.get_prefix(setting.uri), entries = {} }
    for _, sourcefile in ipairs(sourcefiles) do
        local alias, absfile = utils.get_alias(target, sourcefile)
        table.insert(qrcdata.entries, { alias = alias, path = absfile })
    end
    local paths = utils.get_paths(target)
    qrc.write_if_changed(paths.resourceqrc, qrcdata, target:is_rebuilt())
    target:add("files", paths.resourceqrc)
end
