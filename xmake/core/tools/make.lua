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
-- @file        make.lua
--

-- load modules
local os        = require("base/os")
local utils     = require("base/utils")

-- define module: make
local make = make or {}

-- the init function
function make.init(self, name)

    -- save name
    self.name = name or "make"

    -- is verbose?
    self._VERBOSE = utils.ifelse(xmake._OPTIONS.verbose, "-v", "")

end

-- the main function
function make.main(self, mkfile, target)

    -- enable jobs?
    local jobs = ""
    if xmake._OPTIONS.jobs ~= nil then
        if tonumber(xmake._OPTIONS.jobs) ~= 0 then
            jobs = "-j" .. xmake._OPTIONS.jobs
        else
            jobs = "-j"
        end
    end

    -- make command
    local cmd = nil
    if mkfile and os.isfile(mkfile) then
        cmd = string.format("%s -r %s -f %s %s VERBOSE=%s", self.name, jobs, mkfile, target or "", self._VERBOSE)
    else  
        cmd = string.format("%s -r %s %s VERBOSE=%s", self.name, jobs, target or "", self._VERBOSE)
    end

    -- done 
    local ok = os.execute(cmd)
    if ok ~= 0 then

        -- attempt to execute it again for getting the error logs without jobs
        if mkfile and os.isfile(mkfile) then
            cmd = string.format("%s -r -f %s %s VERBOSE=%s", self.name, mkfile, target or "", self._VERBOSE)
        else  
            cmd = string.format("%s -r %s VERBOSE=%s", self.name, target or "", self._VERBOSE)
        end

        -- done
        return os.execute(cmd) == 0
    end

    -- ok
    return true
end

-- return module: make
return make
