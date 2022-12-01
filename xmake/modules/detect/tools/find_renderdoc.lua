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
-- @author      ruki, SirLynix
-- @file        find_renderdoc.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find qmake
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local qmake = find_renderdoc()
-- local qmake, version = find_renderdoc({version = true})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}
    if is_host("windows") then
        opt.paths = opt.paths or {}

        -- add paths from registry
        local regs =
        {
            "HKEY_CLASSES_ROOT\\Applications\\qrenderdoc.exe\\shell\\Open\\Command",
            "HKEY_CURRENT_USER\\SOFTWARE\\Classes\\Applications\\qrenderdoc.exe\\shell\\Open\\Command",
        }
        for _, reg in ipairs(regs) do
            table.insert(opt.paths, function ()
                local value = val("reg " .. reg)
                if value then
                    local p = value:split("\"") 
                    if p and p[1] then
                        return path.translate(p[1])
                    end
                end
            end)
        end
    end

    -- find program
    local program = find_program(opt.program or "qrenderdoc", opt)

    -- find program version
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end

    -- ok?
    return program, version
end
