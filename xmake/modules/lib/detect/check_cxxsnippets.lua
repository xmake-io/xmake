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
-- @author      ruki
-- @file        check_cxxsnippets.lua
--

-- imports
import("lib.detect.check_cxsnippets")

-- check the given c++ snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options
--                  e.g.
--                  { verbose = false, target = [target|option]
--                  , types = {"wchar_t", "char*"}, includes = "stdio.h", funcs = {"sigsetjmp", "sigsetjmp((void*)0, 0)"}
--                  , configs = {defines = "xx", cxflags = ""}}
--
-- funcs:
--      sigsetjmp
--      sigsetjmp((void*)0, 0)
--      sigsetjmp{sigsetjmp((void*)0, 0);}
--      sigsetjmp{int a = 0; sigsetjmp((void*)a, a);}
--
-- @return          true or false
--
-- @code
-- local ok = check_cxxsnippets("void test() {}")
-- local ok = check_cxxsnippets({"void test(){}", "#define TEST 1"}, {types = "wchar_t", includes = "stdio.h"})
-- local ok = check_cxxsnippets({snippet_name = "void test(){}", "#define TEST 1"}, {types = "wchar_t", includes = "stdio.h"})
-- @endcode
--
function main(snippets, opt)
    return check_cxsnippets(snippets, table.join(table.wrap(opt), {sourcekind = "cxx"}))
end

