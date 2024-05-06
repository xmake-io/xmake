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
-- @author      CarbeneHu
-- @file        check_bigendian.lua
--

-- imports
import("lib.detect.check_cxxsnippets")

local check_bigendian_template = [[
#include <inttypes.h>
/* A 16 bit integer is required. */
typedef uint16_t byteorder_int16_t;

/* On a little endian machine, these 16bit ints will give "THIS IS LITTLE ENDIAN."
    On a big endian machine the characters will be exchanged pairwise. */
const byteorder_int16_t info_little[] =  {0x4854, 0x5349, 0x4920, 0x2053, 0x494c, 0x5454, 0x454c, 0x4520, 0x444e, 0x4149, 0x2e4e, 0x0000};

/* on a big endian machine, these 16bit ints will give "THIS IS BIG ENDIAN."
    On a little endian machine the characters will be exchanged pairwise. */
const byteorder_int16_t info_big[] =     {0x5448, 0x4953, 0x2049, 0x5320, 0x4249, 0x4720, 0x454e, 0x4449, 0x414e, 0x2e2e, 0x0000};

int main(int argc, char *argv[])
{
  int require = 0;
  require += info_little[argc];
  require += info_big[argc];
  (void)argv;
  return require;
}]]

local function _byteorder_binary_match(content)
  local match = content:match("THIS IS BIG ENDIAN")
  return match and true or false
end

-- check the endianness of the compiler
--
-- @param opt       the argument options
--                  e.g.
--                  { verbose = false, target = [target|option], includes = "stdio.h"
--                  , configs = {defines = "xx", cxflags = ""}}
--
-- @return          Boolean value whether the compiler is big-endian
--
-- @code
-- local is_bigendian = check_bigendian()
-- @endcode
--
function main(opt)
    local snippets = check_bigendian_template
    local ok, is_bigendian = check_cxxsnippets(snippets, table.join(table.wrap(opt), {binary_match = _byteorder_binary_match}))
    if ok then
        return is_bigendian
    end
end

