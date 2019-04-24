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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check_toolchain.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- check the given tool
function _check_tool(config, toolkind, description, name, cross, pathes, check)

    -- get the program 
    local program = config.get(toolkind)
    if not program then

        -- translate program name to attempt to get `$(env XX)`
        name = vformat(name)
        if #name == 0 then
            return 
        end

        -- attempt to check it 
        local toolname = nil
        if not program then
            local tool = find_tool(name, {program = (cross or "") .. name, pathes = pathes or config.get("bin"), check = check})
            if tool then
                program = tool.program
                toolname = tool.name
            end
        end

        -- check ok?
        if program then 
            config.set(toolkind, program) 
            config.set("__toolname_" .. toolkind, toolname)
            config.save()
        end

        -- trace
        if option.get("verbose") then
            if program then
                cprint("${dim}checking for %s (%s) ... ${color.success}%s", description, toolkind, path.filename(program))
            else
                cprint("${dim}checking for %s (%s: ${bright}%s${clear}) ... ${color.nothing}${text.nothing}", description, toolkind, name)
            end
        end
    end

    -- ok?
    return program
end

-- check the toolchain 
function main(config, name, toolchain)
    for _, toolinfo in ipairs(toolchain.list) do
        if type(toolinfo) == "string" then
            if _check_tool(config, name, toolchain.description, toolinfo) then
                break
            end
        else
            if _check_tool(config, name, toolchain.description, toolinfo.name, toolinfo.cross, toolinfo.pathes, toolinfo.check) then
                break
            end
        end
    end
end

