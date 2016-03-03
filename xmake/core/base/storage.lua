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
-- @file        storage.lua
--

-- define module
local storage = storage or {}

-- load modules
local os    = require("base/os")
local io    = require("base/io")
local path  = require("base/path")
local utils = require("base/utils")

-- get root directory from the given scope name
--
-- global:      ~/.xmake
-- output:      projectdir/output
-- project:     projectdir/.xmake
-- temporary:   tmpdir/.xmake
function storage.rootdir(scopename)

    -- init root directories
    local rootdirs =
    {
        global      = path.translate("~/.xmake")
    ,   output      = path.join(xmake._PROJECT_DIR, "output")
    ,   project     = path.join(xmake._PROJECT_DIR, ".xmake")
    ,   temporary   = path.join(os.tmpdir(), ".xmake")
    }
    storage._ROOTDIRS = storage._ROOTDIRS or {}

    -- get root directory from the given scope name
    local rootdir = storage._ROOTDIRS[scopename] or rootdirs[scopename]
    if not rootdir then
        os.raise("unknown scope %s for storage!", scopename)
    end

    -- ok
    return rootdir
end

-- register storage scope from the given root directory
function storage.register(scopename, rootdir)

    -- check
    assert(scopename and rootdir)

    -- register it
    storage._ROOTDIRS = storage._ROOTDIRS or {}
    storage._ROOTDIRS[scopename] = rootdir
end

-- return module
return storage
