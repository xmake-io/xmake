--!The Make-like Build Utility based on Lua
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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        language.lua
--

-- define module
local sandbox_core_language = sandbox_core_language or {}

-- load modules
local language  = require("language/language")
local raise     = require("sandbox/modules/raise")

-- get the sourcekinds of all languages
function sandbox_core_language.sourcekinds()

    -- get all
    return language.sourcekinds()
end

-- load the language from the given name
function sandbox_core_language.load(name)

    -- load it
    local instance, errors = language.load(name)
    if not instance then
        raise(errors)
    end

    -- ok
    return instance
end

-- load the language from the given kind
function sandbox_core_language.load_from_kind(sourcekind)

    -- load it
    local instance, errors = language.load_from_kind(sourcekind)
    if not instance then
        raise(errors)
    end

    -- ok
    return instance
end

-- return module
return sandbox_core_language
