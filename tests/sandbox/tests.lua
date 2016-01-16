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
-- @file        tests.lua
--

-- define module: tests
local tests = tests or {}

-- load modules
local sandbox = require("sandbox/sandbox")

-- the main function
function tests.main(self, file)

    -- check
    assert(file and #file == 1)

    -- load it
    local ok, errors = sandbox.load(file[1])
    if not ok then
        print(errors)
        return false
    end

    -- ok
    return true
end

-- return module: tests
return tests
