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

local function _check(t, cases)
    for _, case in ipairs(cases) do
        local str, pattern, plain, expected = case[1], case[2], case[3], case[4]
        t:are_equal(string.lastof(str, pattern, plain), expected)
        t:are_equal(str:lastof(pattern, plain), expected)
    end
end

function test_anchored_patterns(t)
    _check(t, {
        {"aaaa", "^a", false, 1},
        {"foofoo", "^foo", false, 1},
        {"baaa", "^a", false, nil},
        {"aa", "^a$", false, nil},
        {"abc", "^", false, 1},
        {"bbb", "^a*", false, 1},
        {"", "^", false, 1},
        {"你好你好", "^你好", false, 1},
        {"^^", "^%^", false, 1}
    })
end

function test_literal_controls(t)
    _check(t, {
        {"1.2.3.4.5", ".", true, 8},
        {"/home/file.txt", "/", true, 6},
        {"/home/file.txt", "/home", true, 1},
        {"a.b.c", ".", true, 4},
        {"a%b%c", "%", true, 4},
        {"x^a^", "^", true, 4},
        {"a$b$", "$", true, 4},
        {"ababa", "aba", true, 3},
        {"abc", "abc", true, 1},
        {"abc", "xyz", true, nil}
    })
end

function test_pattern_controls(t)
    _check(t, {
        {"1.2.3.4.5", "%.", false, 8},
        {"/home/file.txt", "[/\\]", false, 6},
        {"/home/file.txt", "[/\\]home", false, 1},
        {"a.b.c", ".", false, 5},
        {"a%b%c", "%%", false, 4},
        {"x^a^", "%^", false, 4},
        {"a$b$", "%$", false, 4},
        {"ababa", "aba", false, 3},
        {"abc", "abc", false, 1},
        {"abc", "xyz", false, nil},
        {"x123x456", "(%d+)", false, 8},
        {"abc", "", false, 4},
        {"abc", "$", false, 4},
        {"aaa", "a*", false, 4},
        {"", "", false, 1},
        {"foo bar", "%f[%a]", false, 5},
        {"foo bar", "%f[%A]", false, 8}
    })
end

function test_utf8_byte_positions(t)
    _check(t, {
        {"你好你", "你", false, 7},
        {"你好你", "你", true, 7},
        {"a😀b😀", "😀", false, 7},
        {"a😀b😀", "😀", true, 7},
        {"太乙/源码/😀.lua", "[/\\]", false, 14},
        {"太乙/源码/😀.lua", "/", true, 14},
        {"你好", ".", false, 6}
    })
end

function test_existing_lastof(t)
    local tests = import("test", {rootdir = path.join(os.programdir(), "../tests/modules/string"), anonymous = true})
    tests.test_lastof(t)
end
