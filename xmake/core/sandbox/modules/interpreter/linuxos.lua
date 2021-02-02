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
-- @file        linuxos.lua
--

-- load modules
local linuxos = require("base/linuxos")

-- define module
local sandbox_linuxos = sandbox_linuxos or {}

-- export some readonly interfaces
sandbox_linuxos.name      = linuxos.name
sandbox_linuxos.version   = linuxos.version
sandbox_linuxos.kernelver = linuxos.kernelver

-- return module
return sandbox_linuxos

