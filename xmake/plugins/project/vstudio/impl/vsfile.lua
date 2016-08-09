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
-- @file        vsfile.lua
--

-- print file
function _print(self, ...)

    -- print indent
    for i = 1, self._indent do
        self:_write("\t")
    end

    -- print it
    self:_print(...)
end

-- printf file
function _printf(self, ...)

    -- print indent
    for i = 1, self._indent do
        self:_write("\t")
    end

    -- printf it
    self:_printf(...)
end

-- write file
function _write(self, ...)

    -- print indent
    for i = 1, self._indent do
        self:_write("\t")
    end

    -- write it
    self:_write(...)
end

-- enter and print file
function _enter(self, ...)

    -- print it
    self:print(...)

    -- increase indent
    self._indent = self._indent + 1
end

-- leave and print file
function _leave(self, ...)

    -- decrease indent
    if self._indent >= 1 then
        self._indent = self._indent - 1
    else
        self._indent = 0
    end

    -- print it
    self:print(...)
end

-- open file
function open(filepath, mode)
 
    -- open it
    local file = io.open(filepath, mode)

    -- hook print, printf and write
    file._print     = file.print
    file._printf    = file.printf
    file._write     = file.write
    file.print      = _print
    file.printf     = _printf
    file.write      = _write

    -- add enter and leave interfaces
    file.enter  = _enter 
    file.leave  = _leave

    -- init indent
    file._indent = 0

    -- ok?
    return file
end

