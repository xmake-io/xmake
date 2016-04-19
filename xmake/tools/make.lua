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
-- @file        make.lua
--

-- imports
import("core.base.option")

-- init it
function init(shellname)

    -- save name
    _g.shellname = shellname or "make"

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- run it
function run(makefile, target, jobs)

    -- enable jobs?
    if jobs ~= nil then
        if tonumber(jobs) ~= 0 then
            jobs = "-j" .. jobs
        else
            jobs = "-j"
        end
    else
        jobs = ""
    end

    -- is verbose?
    local verbose = ifelse(option.get("verbose"), "-v", "")

    -- run it
    local ok = nil
    if makefile and os.isfile(makefile) then
        ok = os.execute("%s -r %s -f %s %s VERBOSE=%s", _g.shellname, jobs, makefile, target or "", verbose)
    else  
        ok = os.execute("%s -r %s %s VERBOSE=%s", _g.shellname, jobs, target or "", verbose)
    end

    -- failed 
    if ok ~= 0 then

        -- attempt to run it again for getting the error logs without jobs
        if makefile and os.isfile(makefile) then
            ok = os.execute("%s -r -f %s %s VERBOSE=%s", _g.shellname, makefile, target or "", verbose)
        else  
            ok = os.execute("%s -r %s VERBOSE=%s", _g.shellname, target or "", verbose)
        end

    end

    -- always failed?
    if ok ~= 0 then
        raise(ok)
    end

end

-- check the given flags 
function check(flags)

    -- make an empty makefile
    local tmpfile = os.tmpfile()
    io.write(tmpfile, "all:\n")

    -- check it
    os.run("%s %s -f %s", _g.shellname, ifelse(flags, flags, ""), tmpfile)

    -- remove this makefile
    os.rm(tmpfile)
end
