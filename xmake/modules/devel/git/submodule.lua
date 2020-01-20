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
-- @author      OpportunityLiu
-- @file        submodule.lua
--

-- imports
import("main", { alias = "git" })

function main(opt)
    return git().submodule(opt)
end

function add(...)
    return main().add(...)
end

function init(...)
    return main().init(...)
end

function update(...)

    local params = {...}
    if (params.n == 1 and params[1] and type(params[1]) == "table") or params.n == 0 then
        local opt = params[1] or {}
        local pathes = opt.pathes or {}
        opt.pathes = nil
        return main().update(table.unpack(table.wrap(pathes)), opt)
    end

    return main().update(...)
end
