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
local raise   = require("sandbox/modules/raise")

-- define module
local sandbox_linuxos = sandbox_linuxos or {}

-- get linux system name
function sandbox_linuxos.name()
    local name = linuxos.name()
    if not name then
        raise("cannot get the system name of the current linux!")
    end
    return name
end

-- get linux system version
function sandbox_linuxos.version()
    local linuxver = linuxos.version()
    if not linuxver then
        raise("cannot get the system version of the current linux!")
    end
    return linuxver
end

-- get linux kernel version
function sandbox_linuxos.kernelver()
    local kernelver = linuxos.kernelver()
    if not kernelver then
        raise("cannot get the kernel version of the current linux!")
    end
    return kernelver
end

-- return module
return sandbox_linuxos

