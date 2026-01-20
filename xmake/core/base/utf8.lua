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
-- @file        utf8.lua

-- define module: utf8
local utf8 = utf8 or {}

-- @desc        The utf8 module
--              It provides basic support for UTF-8 encoding.
--              It is compatible with Lua 5.3+ utf8 library.
--
-- @interface   utf8.len(s [, i [, j [, lax]]])
-- @interface   utf8.char(...)
-- @interface   utf8.codepoint(s [, i [, j]])
-- @interface   utf8.offset(s, n [, i])
-- @interface   utf8.codes(s [, lax])
--

-- the char pattern
if not utf8.charpattern then
    utf8.charpattern = "[\0-\x7F\xC2-\xFD][\x80-\xBF]*"
end

-- return module: utf8
return utf8
