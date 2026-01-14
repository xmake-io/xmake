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
-- @author      ruki
-- @file        load.lua
--

function _get_apis()
    local apis = {}
    apis.values = {
        -- target.add_xxx
        "target.add_links"
    ,   "target.add_frameworks"
    ,   "target.add_syslinks"
    ,   "target.add_pcflags"
    ,   "target.add_ldflags"
    ,   "target.add_arflags"
    ,   "target.add_shflags"
    ,   "target.add_rpathdirs"  -- @note do not translate path, it's usually an absolute path or contains $ORIGIN/@loader_path
    ,   "target.add_unitdirs"
    ,   "target.add_includedirs"
    ,   "target.add_defines"
    ,   "target.add_undefines"
        -- option.add_xxx
    ,   "option.add_links"
    ,   "option.add_syslinks"
    ,   "option.add_pcflags"
    ,   "option.add_ldflags"
    ,   "option.add_arflags"
    ,   "option.add_shflags"
    ,   "option.add_rpathdirs"
    ,   "option.add_unitdirs"
    ,   "option.add_includedirs"
    ,   "option.add_defines"
    ,   "option.add_undefines"
        -- package.add_xxx
    ,   "package.add_links"
    ,   "package.add_syslinks"
    ,   "package.add_pcflags"
    ,   "package.add_ldflags"
    ,   "package.add_arflags"
    ,   "package.add_shflags"
    ,   "package.add_rpathdirs"
    ,   "package.add_linkdirs"
    ,   "package.add_unitdirs"
    ,   "package.add_includedirs"
    ,   "package.add_defines"
    ,   "package.add_undefines"
        -- toolchain.add_xxx
    ,   "toolchain.add_links"
    ,   "toolchain.add_syslinks"
    ,   "toolchain.add_pcflags"
    ,   "toolchain.add_ldflags"
    ,   "toolchain.add_arflags"
    ,   "toolchain.add_shflags"
    ,   "toolchain.add_rpathdirs"
    ,   "toolchain.add_linkdirs"
    ,   "toolchain.add_unitdirs"
    ,   "toolchain.add_includedirs"
    ,   "toolchain.add_defines"
    ,   "toolchain.add_undefines"
    ,   "toolchain.set_languages"
        -- target.set_xxx
    ,   "target.set_languages"
        -- option.set_xxx
    ,   "option.set_languages"
        -- package.set_xxx
    ,   "package.set_languages"
        -- toolchain.set_xxx
    ,   "toolchain.set_languages"

    }
    apis.paths = {
        -- target.add_xxx
        "target.add_linkdirs"
    ,   "target.add_frameworkdirs"
        -- option.add_xxx
    ,   "option.add_linkdirs"
    }
    return apis
end

function main()
    return {apis = _get_apis()}
end
