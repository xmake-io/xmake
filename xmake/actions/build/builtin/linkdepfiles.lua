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
-- @file        linkdepfiles.lua
--

-- get link depfiles
function main(target)
    local extrafiles = {}
    for _, dep in ipairs(target:orderdeps()) do
        if dep:kind() == "static" then
            table.insert(extrafiles, dep:targetfile())
        end
    end
    local linkdepfiles = target:data("linkdepfiles")
    if linkdepfiles then
        table.join2(extrafiles, linkdepfiles)
    end
    local objectfiles = target:objectfiles()
    local depfiles = objectfiles
    if #extrafiles > 0 then
        depfiles = table.join(objectfiles, extrafiles)
    end
    return depfiles
end
