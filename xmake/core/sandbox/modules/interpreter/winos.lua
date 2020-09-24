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
-- @file        winos.lua
--

-- load modules
local winos = require("base/winos")

-- define module
local sandbox_winos = sandbox_winos or {}

-- export some readonly interfaces
sandbox_winos.registry_query = winos.registry_query
sandbox_winos.logical_drives = winos.logical_drives
sandbox_winos.version        = winos.version

-- return module
return sandbox_winos

