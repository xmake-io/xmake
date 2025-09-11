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
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")
import("private.core.base.is_cross")

-- install package
--
-- @param name  the package name, e.g. zlib
-- @param opt   the options, e.g. {verbose = true}
--
-- @return      true or false
--
function main(name, opt)
    
    -- find nix tools (try modern first, then legacy)
    local nix = find_tool("nix")
    local nix_env = find_tool("nix-env")
    
    if not nix and not nix_env then
        raise("nix not found!")
    end
    
    -- check architecture 
    if is_cross(opt.plat, opt.arch) then
        raise("cannot install package(%s) for cross compilation!", name)
    end
    
    local success = false
    
    -- try modern nix first
    if nix then
        local argv = {"profile", "install", "nixpkgs#" .. name}
        if opt.verbose or option.get("verbose") then
            table.insert(argv, "--verbose")
        end
        
        success = try {function()
            os.vrunv(nix.program, argv)
            return true
        end}
    end
    
    -- fallback to nix-env
    if not success and nix_env then
        local argv = {"-iA", "nixpkgs." .. name}
        if opt.verbose or option.get("verbose") then
            table.insert(argv, "--verbose")
        end
        
        os.vrunv(nix_env.program, argv)
    end
end