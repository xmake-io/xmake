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
-- Copyright (C) 2026-present, Xmake Open Source Community.
--
-- @author      karurochari
-- @file        check_alignof.lua
--

-- imports
import("lib.detect.check_cxxsnippets")

local binary_match_pattern = 'INFO:align%[(%d+)%]'

local check_alignof_template = [[
#if defined(__cplusplus)
    #if __cplusplus >= 201103L
        #define ALIGNOF(type) alignof(type)
    #endif
#elif __STDC_VERSION__ >= 202311L
     #define ALIGNOF(type) alignof(type)
#elif __STDC_VERSION__ >= 201112L
     #define ALIGNOF(type) _Alignof(type)
#elif defined(_MSC_VER)
    #define ALIGNOF(type) __alignof(type)
#elif defined(__GNUC__) || defined(__clang__)
    #define ALIGNOF(type) __alignof__(type)
#else
    #error No known support of alignment detection for your toolchain
#endif 

static char info_align[] =  {'I', 'N', 'F', 'O', ':', 'a','l','i','g','n','[',
  ('0' + ((ALIGNOF(${TYPE}) / 10000)%10)),
  ('0' + ((ALIGNOF(${TYPE}) / 1000)%10)),
  ('0' + ((ALIGNOF(${TYPE}) / 100)%10)),
  ('0' + ((ALIGNOF(${TYPE}) / 10)%10)),
  ('0' +  (ALIGNOF(${TYPE})    % 10)),
  ']',
  '\0'};

int main(int argc, char *argv[]) {
  int require = 0;
  require += info_align[argc];
  (void)argv;
  return require;
}]]

function _binary_match(content)
    local match = content:match(binary_match_pattern)
    if match then
        return match:ltrim("0")
    end
end

-- check the alignment of type
--
-- @param typename  the typename
-- @param opt       the argument options
--                  e.g.
--                  { verbose = false, target = [target|option], includes = "stdio.h"
--                  , configs = {defines = "xx", cxflags = ""}}
--
-- @return          the type alignment
--
-- @code
-- local align = check_alignof("long")
-- local align = check_alignof("std::string", {includes = "string"})
-- @endcode
--
-- check the alignment of a C/C++ type
--
-- @param typename   the type name, e.g. "int", "size_t"
-- @param opt        the options, e.g. {includes = {"stddef.h"}, target = target}
-- @return           the type alignment in bytes, or -1
--
function main(typename, opt)
    local snippets = check_alignof_template:gsub('${TYPE}', typename)
    local ok, size = check_cxxsnippets(snippets, table.join(table.wrap(opt), {binary_match = _binary_match}))
    if ok then
        return size
    end
end

