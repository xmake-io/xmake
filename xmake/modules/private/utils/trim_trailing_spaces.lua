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
-- @file        trim_trailing_spaces.lua
--

function main(pattern)
    for _, filepath in ipairs(os.files(pattern)) do
        local filedata = io.readfile(filepath)
        if filedata then
            local filedata2 = {}
            for _, line in ipairs(filedata:split('\n', {strict = true})) do
                line = line:rtrim()
                table.insert(filedata2, line)
            end
            io.writefile(filepath, table.concat(filedata2, "\n"))
        end
    end
end
