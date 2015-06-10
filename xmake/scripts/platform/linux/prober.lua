--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        prober.lua
--

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local tools     = require("tools/tools")
local config    = require("base/config")
local global    = require("base/global")

-- define module: prober
local prober = prober or {}

-- probe the architecture
function prober._probe_arch()

    -- get the architecture
    local arch = config.get("arch")

    -- ok? 
    if arch then return true end

    -- init the default architecture
    config.set("arch", xmake._ARCH)

    -- ok
    return true
end

-- probe the ccache
function prober._probe_ccache()

    -- ok? 
    local ccache_enable = config.get("ccache")
    if ccache_enable and config.get("__ccache") then return true end

    -- disable?
    if type(ccache_enable) == "boolean" and not ccache_enable then
        config.set("__ccache", nil)
        return true
    end

    -- probe the ccache path
    local ccache_path = tools.probe("ccache", {"/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin"})

    -- probe ok? update it
    if ccache_path then
        config.set("ccache", true)
        config.set("__ccache", ccache_path)
    else
        config.set("ccache", false)
    end

    -- ok
    return true
end

-- probe the project configure 
function prober.config()

    -- probe the architecture
    if not prober._probe_arch() then return end

    -- probe the ccache
    if not prober._probe_ccache() then return end

end

-- probe the global configure 
function prober.global()

    -- probe the ccache
    if not prober._probe_ccache() then return end

end

-- return module: prober
return prober
