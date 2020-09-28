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
-- @file        api.lua
--

-- get apis
function apis()

    -- init apis
    _g.values =
    {
        -- target.set_xxx
        "target.set_config_h_prefix" -- deprecated
        -- target.add_xxx
    ,   "target.add_links"
    ,   "target.add_syslinks"
    ,   "target.add_mflags"
    ,   "target.add_mxflags"
    ,   "target.add_mxxflags"
    ,   "target.add_ldflags"
    ,   "target.add_arflags"
    ,   "target.add_shflags"
    ,   "target.add_defines"
    ,   "target.add_undefines"
    ,   "target.add_defines_h"
    ,   "target.add_undefines_h"
    ,   "target.add_frameworks"
    ,   "target.add_rpathdirs"  -- @note do not translate path, it's usually an absolute path or contains $ORIGIN/@loader_path
        -- option.add_xxx
    ,   "option.add_cincludes"
    ,   "option.add_cxxincludes"
    ,   "option.add_cfuncs"
    ,   "option.add_cxxfuncs"
    ,   "option.add_ctypes"
    ,   "option.add_cxxtypes"
    ,   "option.add_links"
    ,   "option.add_syslinks"
    ,   "option.add_mflags"
    ,   "option.add_mxflags"
    ,   "option.add_mxxflags"
    ,   "option.add_ldflags"
    ,   "option.add_arflags"
    ,   "option.add_shflags"
    ,   "option.add_defines"
    ,   "option.add_defines_if_ok"
    ,   "option.add_defines_h_if_ok"
    ,   "option.add_undefines"
    ,   "option.add_undefines_if_ok"
    ,   "option.add_undefines_h_if_ok"
    ,   "option.add_frameworks"
    ,   "option.add_rpathdirs"
        -- toolchain.add_xxx
    ,   "toolchain.add_links"
    ,   "toolchain.add_syslinks"
    ,   "toolchain.add_mflags"
    ,   "toolchain.add_mxflags"
    ,   "toolchain.add_mxxflags"
    ,   "toolchain.add_ldflags"
    ,   "toolchain.add_arflags"
    ,   "toolchain.add_shflags"
    ,   "toolchain.add_defines"
    ,   "toolchain.add_undefines"
    ,   "toolchain.add_frameworks"
    ,   "toolchain.add_rpathdirs"
    ,   "toolchain.add_linkdirs"
    ,   "toolchain.add_includedirs"
    ,   "toolchain.add_frameworkdirs"
    }
    _g.paths =
    {
        -- target.set_xxx
        "target.set_headerdir"      -- TODO deprecated
    ,   "target.set_config_h"       -- TODO deprecated
    ,   "target.set_config_header"
    ,   "target.set_pcheader"
    ,   "target.set_pcxxheader"
        -- target.add_xxx
    ,   "target.add_headers"        -- TODO deprecated
    ,   "target.add_headerdirs"
    ,   "target.add_headerfiles"
    ,   "target.add_linkdirs"
    ,   "target.add_includedirs"
    ,   "target.add_frameworkdirs"
        -- option.add_xxx
    ,   "option.add_linkdirs"
    ,   "option.add_includedirs"
    ,   "option.add_frameworkdirs"
    }

    -- ok
    return _g
end


