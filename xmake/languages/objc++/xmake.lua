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
-- @file        xmake.lua
--

-- define language
language("objc++")

    -- set source file kinds
    set_sourcekinds(".m", ".mm")

    -- on load
    on_load(function ()

        -- init flags
        _g.mflags       = {}
        _g.mxflags      = {}
        _g.mxxflags     = {}
        _g.ldflags      = {}
        _g.arflags      = {}
        _g.shflags      = {}

        -- init apis
        _g.apis         = {}
        _g.apis.values  = 
        {
            -- target.set_xxx
            "target.set_config_h_prefix"
            -- target.add_xxx
        ,   "target.add_links"
        ,   "target.add_mflags"
        ,   "target.add_mxflags"
        ,   "target.add_mxxflags"
        ,   "target.add_ldflags"
        ,   "target.add_arflags"
        ,   "target.add_shflags"
        ,   "target.add_defines"
        ,   "target.add_undefines"
        ,   "target.add_defines_h"
        ,   "target.add_undefines_h"
            -- option.add_xxx
        ,   "option.add_cincludes"
        ,   "option.add_cxxincludes"
        ,   "option.add_cfuncs"
        ,   "option.add_cxxfuncs"
        ,   "option.add_ctypes"
        ,   "option.add_cxxtypes"
        ,   "option.add_links"
        ,   "option.add_mflags"
        ,   "option.add_mxflags"
        ,   "option.add_mxxflags"
        ,   "option.add_ldflags"
        ,   "option.add_arflags"
        ,   "option.add_shflags"
        ,   "option.add_defines"
        ,   "option.add_defines_if_ok"
        ,   "option.add_defines_h_if_ok"
        ,   "option.add_undefines"
        ,   "option.add_undefines_if_ok"
        ,   "option.add_undefines_h_if_ok"
        }
        _g.apis.pathes  = 
        {
            -- target.set_xxx
            "target.set_headerdir"
        ,   "target.set_config_h"
            -- target.add_xxx
        ,   "target.add_headers"
        ,   "target.add_linkdirs"
        ,   "target.add_includedirs"
            -- option.add_xxx
        ,   "option.add_linkdirs"
        ,   "option.add_includedirs"
        }

        return _g
    end)




