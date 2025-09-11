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
-- @file        find_nix.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find nix
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local nix = find_nix()
-- local nix, version = find_nix({version = true})
--
-- @endcode
--
function main(opt)
    -- init options
    opt = opt or {}
    
    -- add common nix installation paths if no specific program is given
    if not opt.program then
        opt.paths = opt.paths or {}
        local nix_paths = {
            "/nix/var/nix/profiles/default/bin", -- multi-user installation
            "/home/" .. (os.getenv("USER") or "user") .. "/.nix-profile/bin", -- single user installation
            "/run/current-system/sw/bin", -- only on nixos, maybe separate nix logic from nixos logic?
            "/usr/local/bin", -- default path of nix when compiling nix from source
        }
        
        for _, nixpath in ipairs(nix_paths) do
            table.insert(opt.paths, nixpath)
        end
    end
    
    -- find program
    local program = find_program(opt.program or "nix", opt)
    
    -- find program version
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt, function (output)
            -- parse version from "nix (Nix) 2.18.1" format
            return output:match("nix %(Nix%) ([%d%.]+)")
        end)
    end
    
    return program, version
end