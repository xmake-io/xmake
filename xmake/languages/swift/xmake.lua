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
language("swift")

    -- set source file kinds
    set_sourcekinds(".swift")

    -- on load
    on_load(function ()

        -- init flags
        _g.scflags      = {}
        _g.ldflags      = {}
        _g.arflags      = {}
        _g.shflags      = {}

        -- init apis
        _g.apis         = {}
        _g.apis.values  = 
        {
            -- target.add_xxx
            "target.add_links"
        ,   "target.add_scflags"
        ,   "target.add_ldflags"
        ,   "target.add_arflags"
        ,   "target.add_shflags"
            -- option.add_xxx
        ,   "option.add_links"
        ,   "option.add_scflags"
        ,   "option.add_ldflags"
        ,   "option.add_arflags"
        ,   "option.add_shflags"
        }
        _g.apis.pathes  = 
        {
            -- target.add_xxx
            "target.add_linkdirs"
            -- option.add_xxx
        ,   "option.add_linkdirs"
        }

    end)




