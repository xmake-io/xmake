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
-- @file        _lua.lua
--

-- define module: _lua
local _lua = _lua or {}

-- load modules
local os        = require("base/os")
local utils     = require("base/utils")
local config    = require("base/config")
    
-- done the given config
function _lua.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- no script?
    if not options.script then
        return false
    end

    -- the arguments
    local arguments = options.arguments

    -- is string script? 
    if options.string then
        -- load and run string
        local script = loadstring(options.script)
        if script then
            return script(arguments)
        end
    else
        -- attempt to load script from the given file if exists
        local file = options.script
        if not path.is_absolute(file) then
            file = path.absolute(file)
        end

        -- attempt to load script from the xmake tool directory
        if not os.isfile(file) then
            file = xmake._SCRIPTS_DIR .. "/tool/" .. options.script .. ".lua"
        end

        -- load and run the script file
        if os.isfile(file) then
            local script = loadfile(file)
            if script then
                return script(arguments)
            end
        end
    end
 
    -- failed
    utils.error("cannot run this script: %s", options.script)
    return false
end

-- return module: _lua
return _lua
