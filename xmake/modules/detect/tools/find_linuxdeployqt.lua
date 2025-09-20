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
-- @file        find_linuxdeployqt.lua
--

-- imports
import("lib.detect.find_program")

-- find linuxdeployqt
--
-- @param opt   the argument options
--
-- @return      program path or nil
--
-- @code
--
-- local linuxdeployqt = find_linuxdeployqt()
--
-- @endcode
--
function main(opt)
    opt = opt or {}
    
    -- find linuxdeployqt in system PATH
    local program = find_program("linuxdeployqt", opt)
    
    -- if not found, check common installation paths
    if not program then
        -- get home directory safely
        local homedir = os.getenv("HOME") 
        
        local paths = {
            "/usr/local/bin/linuxdeployqt",
            "/usr/bin/linuxdeployqt",
            "/opt/linuxdeployqt/linuxdeployqt",
            path.join(os.tmpdir(), "linuxdeployqt"),
            path.join(homedir, "Downloads/linuxdeployqt"),
            path.join(homedir, "downloads/linuxdeployqt"),
            path.join(homedir, ".local/bin/linuxdeployqt"),
            path.join(homedir, "bin/linuxdeployqt"),
            "/snap/bin/linuxdeployqt",
            "/var/lib/flatpak/exports/bin/linuxdeployqt",
            path.join(homedir, ".local/share/flatpak/exports/bin/linuxdeployqt"),
            path.join(os.curdir(), "linuxdeployqt"),
            path.join(os.curdir(), "tools/linuxdeployqt"),
            path.join(os.curdir(), "bin/linuxdeployqt")
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