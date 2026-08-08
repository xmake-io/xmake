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
-- @file        addon.lua
--

-- define module
local sandbox_core_package_addon = sandbox_core_package_addon or {}

-- load modules
local addon = require("package/addon")

-- inherit some builtin interfaces
sandbox_core_package_addon.installdir   = addon.installdir
sandbox_core_package_addon.registryfile = addon.registryfile
sandbox_core_package_addon.payloaddirs  = addon.payloaddirs
sandbox_core_package_addon.payloads     = addon.payloads
sandbox_core_package_addon.payloads_of  = addon.payloads_of
sandbox_core_package_addon.addons       = addon.addons
sandbox_core_package_addon.addondir     = addon.addondir
sandbox_core_package_addon.register     = addon.register
sandbox_core_package_addon.unregister   = addon.unregister
sandbox_core_package_addon.rescan       = addon.rescan
sandbox_core_package_addon.clear        = addon.clear

-- return module
return sandbox_core_package_addon
