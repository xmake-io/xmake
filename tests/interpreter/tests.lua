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
-- @file        tests.lua
--

-- define module: tests
local tests = tests or {}

-- load modules
local utils         = require("base/utils")
local interpreter   = require("base/interpreter")

-- the main function
function tests.main(self, file)

    -- check
    assert(file and #file == 1)

    -- init interpreter
    local interp = interpreter.init()
    assert(interp)

    -- register api for scopes
    interp:api_register_set_scope("target", "option")
    interp:api_register_add_scope("target", "option")

    -- register api for values
    interp:api_register_set_values("target", nil,           "kind"
                                                        ,   "config_h_prefix"
                                                        ,   "version"
                                                        ,   "strip"
                                                        ,   "options"
                                                        ,   "symbols"
                                                        ,   "warnings"
                                                        ,   "optimize"
                                                        ,   "languages"
                                                        ,   "runscript"
                                                        ,   "installscript"
                                                        ,   "packagescript")
    interp:api_register_add_values("target", nil,           "deps"
                                                        ,   "links"
                                                        ,   "cflags" 
                                                        ,   "cxflags" 
                                                        ,   "cxxflags" 
                                                        ,   "mflags" 
                                                        ,   "mxflags" 
                                                        ,   "mxxflags" 
                                                        ,   "ldflags" 
                                                        ,   "shflags" 
                                                        ,   "options"
                                                        ,   "defines"
                                                        ,   "undefines"
                                                        ,   "defines_h"
                                                        ,   "undefines_h"
                                                        ,   "languages"
                                                        ,   "vectorexts")
    interp:api_register_set_pathes("target", nil,           "headerdir" 
                                                        ,   "targetdir" 
                                                        ,   "objectdir" 
                                                        ,   "config_h")
    interp:api_register_add_pathes("target", nil,           "files"
                                                        ,   "headers" 
                                                        ,   "linkdirs" 
                                                        ,   "includedirs")


    interp:api_register_set_values("option", "option",      "enable"
                                                        ,   "showmenu"
                                                        ,   "category"
                                                        ,   "warnings"
                                                        ,   "optimize"
                                                        ,   "languages"
                                                        ,   "description")
    interp:api_register_add_values("option", "option",      "links" 
                                                        ,   "cincludes" 
                                                        ,   "cxxincludes" 
                                                        ,   "cfuncs" 
                                                        ,   "cxxfuncs" 
                                                        ,   "ctypes" 
                                                        ,   "cxxtypes" 
                                                        ,   "cflags" 
                                                        ,   "cxflags" 
                                                        ,   "cxxflags" 
                                                        ,   "ldflags" 
                                                        ,   "vectorexts"
                                                        ,   "defines"
                                                        ,   "defines_if_ok"
                                                        ,   "defines_h_if_ok"
                                                        ,   "undefines"
                                                        ,   "undefines_if_ok"
                                                        ,   "undefines_h_if_ok")
    interp:api_register_add_pathes("option", "option",      "linkdirs" 
                                                        ,   "includedirs")


    -- load interpreter
    local ok, errors = interp:load(file[1])
    if not ok then
        print(errors)
        return false
    end

    -- dump interpreter
    utils.dump(interp)

    -- ok
    return true
end

-- return module: tests
return tests
