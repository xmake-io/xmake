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
-- @file        crun.lua
--

-- define module: crun
local crun = crun or {}

-- load modules
local io = require("base/io")
local os = require("base/os")

-- the main function
function crun.main(self, ...)

    -- run all command files
    local ok = -1
    for _, v in ipairs(...) do

        -- open file
        local file = io.open(v, "r")
        if file then
            
            -- read command
            local cmd = file:read("*all")
            if cmd and #cmd ~= 0 then
                ok = os.execute(cmd)
            end

            -- exit file
            file:close()

            -- ok?
            if ok ~= 0 then break end
        end
    end

    -- ok?
    return ok
end

-- return module: crun
return crun
