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
-- @file        install.lua
--

-- imports
import("core.project.config")
import("platforms.installer", {rootdir = os.programdir()})

-- install target
function install(target)

    -- check architecture
    local arch = config.get("arch")
    if arch ~= "i386" and arch ~= "x86_64" then
        raise("cannot install target(%s) for arch(%s)!", target:name(), arch)
    end

    -- the scripts
    local scripts =
    {
        binary = installer.install_binary_on_unix
    ,   static = installer.install_library_on_unix
    ,   shared = installer.install_library_on_unix
    }

    -- call script
    local script = scripts[target:get("kind")]
    if script then
        script(target)
    end
end

-- uninstall target
function uninstall(target)

    -- check architecture
    local arch = config.get("arch")
    if arch ~= "i386" and arch ~= "x86_64" then
        raise("cannot uninstall target(%s) for arch(%s)!", target:name(), arch)
    end

    -- the scripts
    local scripts =
    {
        binary = installer.uninstall_binary_on_unix
    ,   static = installer.uninstall_library_on_unix
    ,   shared = installer.uninstall_library_on_unix
    }

    -- call script
    local script = scripts[target:get("kind")]
    if script then
        script(target)
    end
end

