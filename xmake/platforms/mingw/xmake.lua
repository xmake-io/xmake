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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define platform
platform("mingw")

    -- set os
    set_platform_os("windows")

    -- set hosts
    set_platform_hosts("macosx", "linux", "windows")

    -- set archs
    set_platform_archs("i386", "x86_64")

    -- set checker
    set_platform_checker("checker")

    -- on load
    on_platform_load(function ()

        -- imports
        import("core.project.config")
       
        -- init the file formats
        _g.formats          = {}
        _g.formats.static   = {"lib", ".a"}
        _g.formats.object   = {"",    ".o"}
        _g.formats.shared   = {"lib", ".so"}
     
        -- init the toolchains
        _g.tools            = {}
        _g.tools.ccache     = config.get("__ccache")
        _g.tools.cc         = config.get("cc") 
        _g.tools.cxx        = config.get("cxx") 
        _g.tools.as         = config.get("as") 
        _g.tools.ld         = config.get("ld") 
        _g.tools.ar         = config.get("ar")
        _g.tools.sh         = config.get("sh") 
        _g.tools.ex         = config.get("ar") 
        _g.tools.sc         = config.get("sc") 

        -- init flags for architecture
        local archflags = nil
        local arch = config.get("arch")
        if arch then
            if arch == "x86_64" then archflags = "-m64"
            elseif arch == "i386" then archflags = "-m32"
            else archflags = "-arch " .. arch
            end
        end
        _g.cxflags = { archflags }
        _g.asflags = { archflags }
        _g.ldflags = { archflags }
        _g.shflags = { archflags }

    end)



