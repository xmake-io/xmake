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
-- @file        os.lua
--

-- load modules
local io    = require("base/io")
local os    = require("base/os")

-- define module: _os
local _os = _os or {}

-- cat the given file 
function _os.cat(filepath, linecount)
    
    -- cat it
    return io.cat(filepath, linecount)
end

-- only copy the interfaces of os
for k, v in pairs(os) do
    if type(v) == "function" then
        _os[k] = v
    end
end

-- return module: _os
return _os

