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
-- @file        platform.lua
--

-- define module
local sandbox_core_platform = sandbox_core_platform or {}

-- load modules
local platform  = require("platform/platform")
local raise     = require("sandbox/modules/raise")

-- load the current platform
function sandbox_core_platform.load(plat, arch)
    local instance, errors = platform.load(plat, arch)
    if not instance then
        raise(errors)
    end
    return instance
end

-- get the platform os
function sandbox_core_platform.os(plat, arch)
    return platform.os(plat, arch)
end

-- get the all platforms
function sandbox_core_platform.plats()
    return assert(platform.plats())
end

-- get the all toolchains
function sandbox_core_platform.toolchains()
    return assert(platform.toolchains())
end

-- get the all architectures for the given platform
function sandbox_core_platform.archs(plat, arch)
    return platform.archs(plat, arch)
end

-- get the current platform configuration
function sandbox_core_platform.get(name, plat, arch)
    return platform.get(name, plat, arch)
end

-- get the platform tool from the kind
--
-- e.g. cc, cxx, mm, mxx, as, ar, ld, sh, ..
--
function sandbox_core_platform.tool(toolkind, plat, arch)
    return platform.tool(toolkind, plat, arch)
end

-- get the current platform tool configuration
function sandbox_core_platform.toolconfig(name, plat, arch)
    return platform.toolconfig(name, plat, arch)
end

-- return module
return sandbox_core_platform
