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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        vsfile.lua
--

-- init the default indent character
_g.indentchar = '\t'

-- print file
function _print_impl(self, ...)

    -- print indent
    for i = 1, self._indent do
        self:_write_impl(_g.indentchar)
    end

    -- print it
    self:_print_impl(...)
end

-- printf file
function _printf_impl(self, ...)

    -- print indent
    for i = 1, self._indent do
        self:_write_impl(_g.indentchar)
    end

    -- printf it
    self:_printf_impl(...)
end

-- write file
function _write_impl(self, ...)

    -- print indent
    for i = 1, self._indent do
        self:_write_impl(_g.indentchar)
    end

    -- write it
    self:_write_impl(...)
end

-- writef file
function _writef_impl(self, ...)

    -- print indent
    for i = 1, self._indent do
        self:_write_impl(_g.indentchar)
    end

    -- writef it
    self:_writef_impl(...)
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
    file._print_impl  = file.print
    file._printf_impl = file.printf
    file._write_impl  = file.write
    file._writef_impl = file.writef
    file.print        = _print_impl
    file.printf       = _printf_impl
    file.write        = _write_impl
    file.writef       = _writef_impl

    -- add enter and leave interfaces
    file.enter  = _enter
    file.leave  = _leave

    -- init indent
    file._indent = 0

    -- ok?
    return file
end

-- set indent character
function indentchar(ch)
    _g.indentchar = ch or '\t'
end
