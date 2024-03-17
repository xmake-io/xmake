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
-- Copyright (C) 2024, TBOOX Open Source Group.
--
-- @author      CarbeneHu
-- @file        check_bigendian.lua
--

-- check compiler byteorder(big-endian/little-endian) add to macro definition
--
-- from https://github.com/xmake-io/xmake/issues/4843
--
-- e.g.
--
-- check_bigendian("IS_BIG_ENDIAN") => IS_BIG_ENDIAN=0
--
-- configvar_check_bigendian("IS_BIG_ENDIAN") => #define IS_BIG_ENDIAN 0
--

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

function check_bigendian(definition, opt)
  opt = opt or {}
  local optname = opt.name or ("__" .. definition)
  interp_save_scope()
  option(optname)
      set_showmenu(false)
      add_cxxsnippets(definition, check_bigendian_template, {binary_match = _byteorder_binary_match})
      if opt.links then
          add_links(opt.links)
      end
      if opt.includes then
          add_cxxincludes(opt.includes)
      end
      if opt.languages then
          set_languages(opt.languages)
      end
      if opt.cflags then
          add_cflags(opt.cflags)
      end
      if opt.cxflags then
          add_cxflags(opt.cxflags)
      end
      if opt.defines then
          add_defines(opt.defines)
      end
      if opt.warnings then
          set_warnings(opt.warnings)
      end
      after_check(function(option)
          option:add("defines", definition .. "=" .. (option:value() and 1 or 0))
      end)
  option_end()
  interp_restore_scope()
  add_options(optname)
end

function configvar_check_bigendian(definition, opt)
  opt = opt or {}
  local optname = opt.name or ("__" .. definition)
  local defname, defval = table.unpack(definition:split('='))
  interp_save_scope()
  option(optname)
      set_showmenu(false)
      add_cxxsnippets(definition, check_bigendian_template, {binary_match = _byteorder_binary_match})
      if opt.default == nil then
          set_configvar(defname, defval or 1, { quote = false })
      end
      if opt.links then
          add_links(opt.links)
      end
      if opt.includes then
          add_cxxincludes(opt.includes)
      end
      if opt.languages then
          set_languages(opt.languages)
      end
      if opt.cflags then
          add_cflags(opt.cflags)
      end
      if opt.cxflags then
          add_cxflags(opt.cxflags)
      end
      if opt.defines then
          add_defines(opt.defines)
      end
      if opt.warnings then
          set_warnings(opt.warnings)
      end
      after_check(function(option)
          option:set("configvar", defname, option:value() and 1 or 0, { quote = false })
      end)
  option_end()
  interp_restore_scope()
  if opt.default == nil then
      add_options(optname)
  else
      set_configvar(defname, has_config(optname) and (defval or 1) or opt.default, { quote = false })
  end
end
