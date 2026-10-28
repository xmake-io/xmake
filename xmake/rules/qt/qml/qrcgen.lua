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
-- @file        qrcgen.lua
--

-- imports
import("core.base.json")
import("qrc")

-- generate the qml qrc file from the manifest, called by `batchcmds:lua()`
--
-- @param qrcfile       the output qrc file
-- @param manifestfile  the manifest file of the QML module
--
function main(qrcfile, manifestfile)
    local manifest = json.loadfile(manifestfile)
    -- always rewrite the qrc to update its mtime, so that rcc will be recompiled
    os.mkdir(path.directory(qrcfile))
    io.writefile(qrcfile, qrc.render_qrc(manifest))
end
