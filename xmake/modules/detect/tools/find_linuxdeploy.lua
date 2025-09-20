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
-- @file        find_linuxdeploy.lua
--

-- imports
import("lib.detect.find_program")

-- find linuxdeploy
--
-- @param opt   the argument options
--
-- @return      program path or nil
--
-- @code
--
-- local linuxdeploy = find_linuxdeploy()
--
-- @endcode
--
function main(opt)
    opt = opt or {}
    
    -- find linuxdeploy in system PATH
    local program = find_program("linuxdeploy", opt)
    
    -- if not found, check common installation paths
    if not program then
        local homedir = os.getenv("HOME") 
        local paths = {
            "/usr/local/bin/linuxdeploy",
            "/usr/bin/linuxdeploy",
            "/opt/linuxdeploy/linuxdeploy",
            path.join(os.tmpdir(), "linuxdeploy"),
            path.join(homedir, "Downloads/linuxdeploy"),
            path.join(homedir, "downloads/linuxdeploy"),
            path.join(homedir, ".local/bin/linuxdeploy"),
            path.join(homedir, "bin/linuxdeploy"),
            "/snap/bin/linuxdeploy",
            "/var/lib/flatpak/exports/bin/linuxdeploy",
            path.join(homedir, ".local/share/flatpak/exports/bin/linuxdeploy"),
            path.join(os.curdir(), "linuxdeploy"),
            path.join(os.curdir(), "tools/linuxdeploy"),
            path.join(os.curdir(), "bin/linuxdeploy")
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