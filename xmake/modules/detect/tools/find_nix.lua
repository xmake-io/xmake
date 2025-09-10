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
    
    -- find program
    local program = find_program(opt.program or "nix", opt)
    
    -- nix might be installed in different locations
    if not program and not opt.program then
        -- check common nix installation paths
        local paths = {
            "/nix/var/nix/profiles/default/bin/nix", -- multi-user installation
            "/home/" .. (os.getenv("USER") or "user") .. "/.nix-profile/bin/nix", -- single user installation
            "/run/current-system/sw/bin/nix", -- only on nixos, maybe separate nix logic from nixos logic?
            "/usr/local/bin/nix", -- default path of nix when compiling nix from source
        }
        
        for _, nixpath in ipairs(paths) do
            if os.isfile(nixpath) then
                program = nixpath
                break
            end
        end
    end
    
    -- find program version
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt, function (output)
            -- parse version from "nix (Nix) 2.18.1" format
            return output:match("nix %(Nix%) ([%d%.]+)")
        end)
    end
    
    -- validate that nix is working
    if program then
        local ok = try {function ()
            return os.iorunv(program, {"--version"}, {stdout = os.nuldev()})
        end}
        if not ok then
            program = nil
        end
    end
    
    return program, version
end