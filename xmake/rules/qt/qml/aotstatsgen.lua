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
-- @file        aotstatsgen.lua
--

-- generate the aot stats file list from the sidecar files which exist
--
-- Some files (e.g. .mjs module files) do not produce a sidecar file for
-- every Qt version, so we cannot pass the whole list to qmlaotstats.
--
-- @param listfile      the output list file
-- @param ...           the sidecar files
--
function main(listfile, ...)
    local files = {}
    for _, file in ipairs({...}) do
        if os.isfile(file) then
            table.insert(files, file)
        end
    end
    os.mkdir(path.directory(listfile))
    io.writefile(listfile, table.concat(files, "\n") .. "\n")
end
