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
-- @author      RubMaker
-- @file        find_appimagetool.lua
--

-- imports
import("lib.detect.find_program")

-- find appimagetool
--
-- @param opt   the argument options
--
-- @return      program path or nil
--
-- @code
--
-- local appimagetool = find_appimagetool()
--
-- @endcode
--
function main(opt)
    opt = opt or {}
    
    -- find appimagetool in system PATH
    local program = find_program("appimagetool", opt)
    
    -- if not found, check common installation paths
    if not program then
        local paths = {
            "/usr/local/bin/appimagetool",
            "/usr/bin/appimagetool",
            "/opt/appimagetool/appimagetool"
        }
        
        for _, p in ipairs(paths) do
            if os.isfile(p) and os.isexec(p) then
                program = p
                break
            end
        end
    end
    
    return program
end