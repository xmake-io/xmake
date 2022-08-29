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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      Arthapz, ruki
-- @file        stl_headers.lua
--

-- imports
import("core.base.hashset")

-- the stl headers list
function _stl_headers()
    return {
    "algorithm",
    "forward_list",
    "numbers",
    "stop_token",
    "any",
    "fstream",
    "numeric",
    "streambuf",
    "array",
    "functional",
    "optional",
    "string",
    "atomic",
    "future",
    "ostream",
    "string_view",
    "barrier",
    "initializer_list",
    "queue",
    "bit",
    "iomanip",
    "random",
    "syncstream",
    "bitset",
    "ios",
    "ranges",
    "system_error",
    "charconv",
    "iosfwd",
    "ratio",
    "thread",
    "chrono",
    "iostream",
    "regex",
    "tuple",
    "codecvt",
    "istream",
    "scoped_allocator",
    "typeindex",
    "compare",
    "iterator",
    "semaphore",
    "typeinfo",
    "complex",
    "latch",
    "set",
    "type_traits",
    "concepts",
    "limits",
    "shared_mutex",
    "unordered_map",
    "condition_variable",
    "list",
    "source_location",
    "stacktrace",
    "unordered_set",
    "coroutine",
    "locale",
    "span",
    "utility",
    "deque",
    "map",
    "spanstream",
    "valarray",
    "exception",
    "memory",
    "sstream",
    "variant",
    "execution",
    "memory_resource",
    "stack",
    "vector",
    "filesystem",
    "mutex",
    "version",
    "format",
    "new",
    "type_traits",
    "string_view",
    "stdexcept",
    "condition_variable",
    "print",
    "flat_map",
    "flat_set",
    "mdspan",
    "stdfloat",
    "generator",
    "csetjmp",
    "csignal",
    "cstdarg",
    "cstddef",
    "cstdlib",
    "cfloat",
    "cinttypes",
    "climits",
    "cstdint",
    "cassert",
    "cerrno",
    "cctype",
    "cstring",
    "cuchar",
    "cwchar",
    "cwctype",
    "cfenv",
    "cmath",
    "ctime",
    "clocale",
    "expected",
    "cstdio"}
end

-- get all stl headers
function get_stl_headers()
    local stl_headers = _g.stl_headers
    if stl_headers == nil then
        stl_headers = hashset.from(_stl_headers())
        _g.stl_headers = stl_headers or false
    end
    return stl_headers or nil
end

-- is stl header?
function is_stl_header(header)
    if header:startswith("experimental/") then
        header = header:sub(14, -1)
    end
    return get_stl_headers():has(header)
end

