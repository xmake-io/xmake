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
-- @file        xmake.lua
--

includes("@builtin/check/check_cflags.lua")
includes("@builtin/check/check_cfuncs.lua")
includes("@builtin/check/check_cincludes.lua")
includes("@builtin/check/check_csnippets.lua")
includes("@builtin/check/check_ctypes.lua")
includes("@builtin/check/check_cxxflags.lua")
includes("@builtin/check/check_cxxfuncs.lua")
includes("@builtin/check/check_cxxincludes.lua")
includes("@builtin/check/check_cxxsnippets.lua")
includes("@builtin/check/check_cxxtypes.lua")
includes("@builtin/check/check_features.lua")
includes("@builtin/check/check_links.lua")
includes("@builtin/check/check_macros.lua")
includes("@builtin/check/check_syslinks.lua")
includes("@builtin/check/check_sizeof.lua")
includes("@builtin/check/check_bigendian.lua")
