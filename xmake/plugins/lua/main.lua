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

-- get script from stdin
function _get_script_from_stdin()
    local script_content = io.read("*a")
    if script_content then
        -- remove utf8 bom
        if script_content:startswith(utf8.bom) then
            script_content = script_content:sub(#utf8.bom + 1)
        end
        local shell = os.shell()
        if shell == "cmd" or shell == "powershell" or shell == "pwsh" or is_host("windows") then
            script_content = script_content:trim()
            script_content = script_content:trim('\"')
            script_content = script_content:replace("\\n", "\n", {plain = true}):replace("\\r", "\r", {plain = true})
        end

        if not script_content:find("function main", 1, true) then
            script_content = "function main(...)\n" .. script_content .. "\nend"
        end

        local script = os.tmpfile() .. ".lua"
        io.writefile(script, script_content)
        return script
    end
end

function main()

    -- list builtin scripts
    if option.get("list") then
        return _list()
    end

    -- run script
    local script = option.get("script")
    local arguments = option.get("arguments")
    local from_stdin = option.get("stdin")
    if script or from_stdin then

        -- run script from stdin?
        local script_file_to_remove
        if from_stdin then
            local script_path = _get_script_from_stdin()
            if script_path then
                script = script_path
                script_file_to_remove = script_path
            end
        end

        if script then
            run_script(script, {
                curdir = os.workingdir(),
                verbose = option.get("verbose"),
                diagnosis = option.get("diagnosis"),
                command = option.get("command"),
                arguments = arguments,
                deserialize = option.get("deserialize")})

            if script_file_to_remove then
                os.tryrm(script_file_to_remove)
            end
        end
    else
        -- enter interactive mode
        sandbox.interactive()
    end
end
