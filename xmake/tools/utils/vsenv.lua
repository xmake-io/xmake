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
-- @file        vsenv.lua
--

-- imports
import("core.project.config")

-- enter the given environment
function _enter(name)

    -- get the pathes for the vs environment
    local old = nil
    local new = config.get("__vsenv_" .. name)
    if new then

        -- get the current pathes
        old = os.getenv(name) or ""

        -- append the current pathes
        new = new .. ";" .. old

        -- update the pathes for the environment
        os.setenv(name, new)
    end

    -- return the previous environment
    return old;
end

-- leave the given environment
function _leave(name, old)

    -- restore the previous environment
    if old then 
        os.setenv(name, old)
    end
end

-- enter the vs environment
function enter()

    _g.pathes    = _enter("path")
    _g.libs      = _enter("lib")
    _g.includes  = _enter("include")
    _g.libpathes = _enter("libpath")

end

-- leave the vs environment
function leave()

    _leave("path",      _g.pathes)
    _leave("lib",       _g.libs)
    _leave("include",   _g.includes)
    _leave("libpath",   _g.libpathes)

end
