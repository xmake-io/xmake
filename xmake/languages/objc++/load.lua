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
-- @file        load.lua
--

function _get_apis()
    local apis = {}
    apis.values = {
        -- target.add_xxx
        "target.add_links"
    ,   "target.add_syslinks"
    ,   "target.add_mflags"
    ,   "target.add_mxflags"
    ,   "target.add_mxxflags"
    ,   "target.add_ldflags"
    ,   "target.add_arflags"
    ,   "target.add_shflags"
    ,   "target.add_defines"
    ,   "target.add_undefines"
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
    ,   "option.add_undefines"
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
    ,   "toolchain.add_sysincludedirs"
    ,   "toolchain.add_frameworkdirs"
    }
    apis.paths = {
        -- target.set_xxx
        "target.set_headerdir"      -- TODO deprecated
    ,   "target.set_config_header"
    ,   "target.set_pcheader"
    ,   "target.set_pcxxheader"
        -- target.add_xxx
    ,   "target.add_headers"        -- TODO deprecated
    ,   "target.add_headerfiles"
    ,   "target.add_linkdirs"
    ,   "target.add_includedirs"
    ,   "target.add_sysincludedirs"
    ,   "target.add_frameworkdirs"
        -- option.add_xxx
    ,   "option.add_linkdirs"
    ,   "option.add_includedirs"
    ,   "option.add_sysincludedirs"
    ,   "option.add_frameworkdirs"
    }
    return apis
end

function main()
    return {apis = _get_apis()}
end


