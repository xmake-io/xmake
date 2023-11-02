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
-- @file        check_sizeof.lua
--

-- imports
import("lib.detect.check_cxxsnippets")

local binary_match_pattern = 'INFO:size%[(%d+)%]'

local check_sizeof_template = [[
#define SIZE (sizeof(${TYPE}))
static char info_size[] =  {'I', 'N', 'F', 'O', ':', 's','i','z','e','[',
  ('0' + ((SIZE / 10000)%10)),
  ('0' + ((SIZE / 1000)%10)),
  ('0' + ((SIZE / 100)%10)),
  ('0' + ((SIZE / 10)%10)),
  ('0' +  (SIZE    % 10)),
  ']',
  '\0'};

int main(int argc, char *argv[]) {
  int require = 0;
  require += info_size[argc];
  (void)argv;
  return require;
}]]

function _binary_match(content)
    local match = content:match(binary_match_pattern)
    if match then
        return match:ltrim("0")
    end
end

-- check the size of type
--
-- @param typename  the typename
-- @param opt       the argument options
--                  e.g.
--                  { verbose = false, target = [target|option], includes = "stdio.h"
--                  , configs = {defines = "xx", cxflags = ""}}
--
-- @return          the type size
--
-- @code
-- local size = check_sizeof("long")
-- local size = check_sizeof("std::string", {includes = "string"})
-- @endcode
--
function main(typename, opt)
    local snippets = check_sizeof_template:gsub('${TYPE}', typename)
    local ok, size = check_cxxsnippets(snippets, table.join(table.wrap(opt), {binary_match = _binary_match}))
    if ok then
        return size
    end
end

