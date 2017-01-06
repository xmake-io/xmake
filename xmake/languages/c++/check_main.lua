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
-- @file        check_main.lua
--


-- check it
function main(sourcefile)

    -- load source code
    local sourcecode = io.read(sourcefile)

    -- remove comment first
    sourcecode = sourcecode:gsub("/%*.-%*/", "")
    sourcecode = sourcecode:gsub("//.-\n", "\n")

    -- find int main(int argc, char** argv) {}
    if sourcecode:find("%s+main%s*%(.-%)") then
        return true
    end

    -- no main function
    return false
end


