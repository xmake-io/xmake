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
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.sandbox.module")
import("core.sandbox.sandbox")
import("core.project.project")
import("utils.run_script")

-- get all lua scripts
function scripts()
    local names = {}
    local oldir = os.cd(os.workingdir())
    local files = os.files(path.join(os.scriptdir(), "scripts/*.lua"))
    for _, file in ipairs(files) do
        table.insert(names, path.basename(file))
    end
    os.cd(oldir)
    return names
end

-- list all lua scripts
function _list()
    print("scripts:")
    for _, file in ipairs(scripts()) do
        print("    " .. file)
    end
end

function main()

    -- list builtin scripts
    if option.get("list") then
        return _list()
    end

    -- run script
    local script = option.get("script")
    if script then
        return run_script(script, {
            curdir = os.workingdir(),
            verbose = option.get("verbose"),
            diagnosis = option.get("diagnosis"),
            command = option.get("command"),
            arguments = option.get("arguments"),
            deserialize = option.get("deserialize")})
    end

    -- enter interactive mode
    sandbox.interactive()
end
