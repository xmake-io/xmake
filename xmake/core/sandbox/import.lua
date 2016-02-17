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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        import.lua
--

-- load modules
local utils = require("base/utils")

-- import module
function sandbox_builtin_import(name)

    -- load module
    local module = require("sandbox/import/" .. name)
    if not module then
        utils.error("cannot import module: %s", name)
        utils.abort()
    end

    -- get the parent scope
    local scope_parent = getfenv(2)
    assert(scope_parent)

    -- this module has been imported?
    if rawget(scope_parent, name) then
        utils.error("this module: %s has been imported!", name)
        utils.abort()
    end

    -- import this module into the parent scope
    scope_parent[name] = module
end

-- load module
return sandbox_builtin_import

