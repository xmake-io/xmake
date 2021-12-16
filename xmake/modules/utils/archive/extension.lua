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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        extension.lua
--

-- imports
import("core.base.hashset")

-- get the archive extension
function main(archivefile)
    local extension = ""
    local filename = path.filename(archivefile)
    local extensionset = hashset.from({".zip", ".7z", ".gz", ".xz", ".tgz", ".bz2", ".tar", ".tar.gz", ".tar.xz", ".tar.bz2"})
    local i = filename:lastof(".", true)
    if i then
        local p = filename:sub(1, i - 1):lastof(".", true)
        if p and extensionset:has(filename:sub(p)) then i = p end
        extension = filename:sub(i)
    end
    return extensionset:has(extension) and extension or ""
end
