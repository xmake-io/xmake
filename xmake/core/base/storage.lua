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

-- init the storage instance
--
-- global:      ~/.xmake
-- output:      projectdir/output
-- project:     projectdir/.xmake
-- temporary:   tmpdir/.xmake
function storage._init(rootdir)

end

-- the global storage instance
function storage.global()

    -- get it
    return storage._init(path.translate("~/.xmake"))
end

-- the output storage instance
function storage.output()

    -- TODO 
    -- get it
    return storage._init(path.join(xmake._PROJECT_DIR, "output"))
end

-- the project storage instance
function storage.project()

    -- get it
    return storage._init(path.join(xmake._PROJECT_DIR, ".xmake"))
end

-- the temporary storage instance
function storage.temporary()

    -- get it
    return storage._init(path.join(os.tmpdir(), ".xmake"))
end

-- return module
return storage
