--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        import.lua
--

-- load modules
local os    = require("base/os")
local path  = require("base/path")
local utils = require("base/utils")

-- import module
function sandbox_import(name)

    -- load module
    local module = require("sandbox/import/" .. name)
    if not module then
        os.raise("cannot import module: %s", name)
    end

    -- get module name
    local modulename = path.basename(name)
    if not modulename then
        os.raise("cannot get module name for %s", name)
    end

    -- get the parent scope
    local scope_parent = getfenv(2)
    assert(scope_parent)

    -- this module has been imported?
    if rawget(scope_parent, modulename) then
        os.raise("this module: %s has been imported!", name)
    end

    -- import this module into the parent scope
    scope_parent[modulename] = module

    -- return it
    return module
end

-- load module
return sandbox_import

