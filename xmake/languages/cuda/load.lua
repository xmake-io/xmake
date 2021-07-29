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
    ,   "target.add_cugencodes"
    ,   "target.add_cuflags"
    ,   "target.add_culdflags"
    ,   "target.add_ldflags"
    ,   "target.add_arflags"
    ,   "target.add_shflags"
    ,   "target.add_defines"
    ,   "target.add_undefines"
    ,   "target.add_rpathdirs"  -- @note do not translate path, it's usually an absolute path or contains $ORIGIN/@loader_path
        -- option.add_xxx
    ,   "option.add_links"
    ,   "option.add_syslinks"
    ,   "option.add_cugencodes"
    ,   "option.add_cuflags"
    ,   "option.add_culdflags"
    ,   "option.add_ldflags"
    ,   "option.add_arflags"
    ,   "option.add_shflags"
    ,   "option.add_defines"
    ,   "option.add_undefines"
    ,   "option.add_rpathdirs"
        -- toolchain.add_xxx
    ,   "toolchain.add_links"
    ,   "toolchain.add_syslinks"
    ,   "toolchain.add_cugencodes"
    ,   "toolchain.add_cuflags"
    ,   "toolchain.add_culdflags"
    ,   "toolchain.add_ldflags"
    ,   "toolchain.add_arflags"
    ,   "toolchain.add_shflags"
    ,   "toolchain.add_defines"
    ,   "toolchain.add_undefines"
    ,   "toolchain.add_rpathdirs"
    }
    apis.paths = {
        -- target.add_xxx
        "target.add_linkdirs"
    ,   "target.add_includedirs"
    ,   "target.add_sysincludedirs"
        -- option.add_xxx
    ,   "option.add_linkdirs"
    ,   "option.add_sysincludedirs"
    }
    return apis
end

function main()
    return {apis = _get_apis()}
end


