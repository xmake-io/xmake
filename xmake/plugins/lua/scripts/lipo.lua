--!The Make-like Build Utility based on Lua
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
-- @file        lipo.lua
--

-- imports
import("core.tool.tool")

-- main
--
-- .e.g.
--
-- xmake l lipo "-create -arch armv7 file -arch arm64 file -output file"
function main(...)

    -- get arguments
    local args = ...
    if not args or #args ~= 1 then
        raise("invalid arguments!")
    end
    args = args[1]

    -- check the lipo
    local lipo = tool.check("xcrun lipo", nil, function (shellname)
                        os.run("xcrun -find lipo")
                    end)
    assert(lipo, "lipo not found!")

    -- run it
    os.run("%s %s", lipo, args)
end

