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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        clone.lua
--

-- imports
import("main", { alias = "git" })
import("asgiturl")

-- clone url
--
-- @param url   the git url
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
-- 
-- git.clone("git@github.com:xmake-io/xmake.git")
-- git.clone("git@github.com:xmake-io/xmake.git", {depth = 1, branch = "master", outputdir = "/tmp/xmake"})
--
-- @endcode
--
function main(...)

    local params = table.pack(...)
    if type(params[2]) == "table" and params[2].outputdir then
        local outputdir = params[2].outputdir
        params[2].outputdir = nil
        table.insert(params, 2, path.absolute(outputdir))
        params.n = params.n + 1
    end

    for i = 1, params.n do
        -- the first string param is remote url, try format it
        local param = params[i]
        if type(param) == "string" then
            params[i] = asgiturl(param) or param
            break
        end
    end

    return git().clone(table.unpack(params, 1, params.n))
end
