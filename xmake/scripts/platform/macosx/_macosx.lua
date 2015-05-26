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
-- @file        _macosx.lua
--

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")

-- define module: _macosx
local _macosx = _macosx or {}

-- init configure
function _macosx.init(configs)

    -- init host
    configs.host = "macosx"

    -- init the file name formats
    configs.formats = {}
    configs.formats.static = {"lib", ".a"}
    configs.formats.object = {"",    ".o"}
    configs.formats.shared = {"",    ".dylib"}

    -- init the architecture scopes
    configs.archs = {}
    configs.archs.x86 = {}
    configs.archs.x64 = {}

end

-- probe the xcode application directory
function _macosx._probe_xcode(configs)

    -- get the xcode
    local xcode = configs.xcode

    -- ok? 
    if xcode and xcode ~= "auto" then return true end

    -- clear it first
    xcode = nil

    -- attempt to get the default directory 
    if not xcode then
        if os.isdir("/Applications/Xcode.app") then
            xcode = "/Applications/Xcode.app"
        end
    end

    -- attempt to match the other directories
    if not xcode then
        local dirs = os.match("/Applications/Xcode*.app", true)
        if dirs and table.getn(dirs) ~= 0 then
            xcode = dirs[1]
        end
    end

    -- probe ok? update it
    if xcode then
        configs.xcode = xcode
    else
        -- failed
        utils.error("The Xcode directory is unknown now, please config it first!")
        utils.error("    - xmake config --xcode=xxx")
        utils.error("or  - xmake global --xcode=xxx")
        return false
    end

    -- ok
    return true
end

-- probe the xcode sdk version
function _macosx._probe_xcode_sdkver(configs)

    -- get the xcode sdk version
    local xcode_sdkver = configs.xcode_sdkver

    -- ok? 
    if xcode_sdkver and xcode_sdkver ~= "auto" then return true end

    -- clear it first
    xcode_sdkver = nil

    -- attempt to match the directory
    if not xcode_sdkver then
        local dirs = os.match("/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX*.sdk", true)
        if dirs and table.getn(dirs) ~= 0 then
            xcode_sdkver = string.match(dirs[1], "%d+%.%d+")
        end
    end

    -- probe ok? update it
    if xcode_sdkver then
        configs.xcode_sdkver = xcode_sdkver
    else
        -- failed
        utils.error("The Xcode SDK version is unknown now, please config it first!")
        utils.error("    - xmake config --xcode_sdkver=xxx")
        utils.error("or  - xmake global --xcode_sdkver=xxx")
        return false
    end

    -- ok
    return true
end

-- probe the configure and update the values with "auto"
function _macosx.probe(configs)

    -- probe the xcode application directory
    if not _macosx._probe_xcode(configs) then return end

    -- probe the xcode sdk version
    if not _macosx._probe_xcode_sdkver(configs) then return end

end

-- get the option menu for action: xmake config or global
function _macosx.menu(action)

    -- init config option menu
    _macosx._MENU_CONFIG = _macosx._MENU_CONFIG or
            {   {}   
            ,   {nil, "mm",             "kv", nil,          "The Objc Compiler"                 }
            ,   {nil, "mx",             "kv", nil,          "The Objc/c++ Compiler"             }
            ,   {nil, "mxx",            "kv", nil,          "The Objc++ Compiler"               }
            ,   {nil, "mflags",         "kv", nil,          "The Objc Compiler Flags"           }
            ,   {nil, "mxflags",        "kv", nil,          "The Objc/c++ Compiler Flags"       }
            ,   {nil, "mxxflags",       "kv", nil,          "The Objc++ Compiler Flags"         }
            ,   {}
            ,   {nil, "xcode",          "kv", "auto",       "The Xcode Application Directory"   }
            ,   {nil, "xcode_sdkver",   "kv", "auto",       "The SDK Version for Xcode"         }
            ,   }

    -- init global option menu
    _macosx._MENU_GLOBAL = _macosx._MENU_GLOBAL or
            {   {}
            ,   {nil, "xcode",          "kv", "auto",       "The Xcode Application Directory"   }
            ,   {nil, "xcode_sdkver",   "kv", "auto",       "The SDK Version for Xcode"         }
            ,   }

    -- get the option menu
    if action == "config" then
        return _macosx._MENU_CONFIG
    elseif action == "global" then
        return _macosx._MENU_GLOBAL
    end
end

-- return module: _macosx
return _macosx
