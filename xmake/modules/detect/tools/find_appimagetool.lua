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
-- @author      RubMaker
-- @file        find_appimagetool.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find appimagetool
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program
--
-- @code
--
-- local appimagetool = find_appimagetool()
--
-- @endcode
--
function main(opt)
    -- init options
    opt = opt or {}
    
    -- add common appimagetool installation paths if no specific program is given
    if not opt.program then
        opt.paths = opt.paths or {}
        local appimagetool_paths = {
            "/usr/bin",                    -- standard system path
            "/usr/local/bin",              -- local installation
            "/opt/appimagetool",           -- custom installation directory
            path.join(os.getenv("HOME") or "~", ".local/bin")  -- user local bin
        }
        
        opt.paths = table.wrap(opt.paths)
        for _, apppath in ipairs(appimagetool_paths) do
            table.insert(opt.paths, apppath)
        end
    end
    
    -- find program
    local program = find_program(opt.program or "appimagetool", opt)
    return program
end