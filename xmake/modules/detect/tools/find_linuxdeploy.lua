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
-- @file        find_linuxdeploy.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find linuxdeploy
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local linuxdeploy = find_linuxdeploy()
--
-- @endcode
--
function main(opt)
    -- init options
    opt = opt or {}
    
    -- add common linuxdeploy installation paths if no specific program is given
    if not opt.program then
        opt.paths = opt.paths or {}
        local homedir = os.getenv("HOME") or "~"
        local linuxdeploy_paths = {
            "/usr/local/bin",                    -- standard system path
            "/usr/bin",                          -- system binary path
            "/opt/linuxdeploy",                  -- custom installation directory
            path.join(homedir, ".local/bin"),      -- user local bin
            path.join(homedir, "bin"),             -- user bin
            path.join(homedir, "Downloads"),       -- common download location
            path.join(homedir, "downloads"),       -- lowercase download location
            os.tmpdir(),                           -- temporary directory
            "/snap/bin",                          -- snap packages
            "/var/lib/flatpak/exports/bin",       -- flatpak system
            path.join(homedir, ".local/share/flatpak/exports/bin"), -- flatpak user
            path.join(os.curdir(), "tools"),       -- project tools directory
            path.join(os.curdir(), "bin")          -- project bin directory
        }
        
        opt.paths = table.wrap(opt.paths)
        for _, deploypath in ipairs(linuxdeploy_paths) do
            table.insert(opt.paths, deploypath)
        end
    end
    
    -- find program
    local program = find_program(opt.program or "linuxdeploy", opt)
    return program
end