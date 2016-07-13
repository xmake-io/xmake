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
-- @file        process.lua
--

-- load modules
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")
local vformat   = require("sandbox/modules/vformat")

-- define module
local sandbox_process = sandbox_process or {}

-- open process
function sandbox_process.open(command, outfile, errfile) 

    -- check
    assert(command)

    -- format command first
    command = vformat(command)

    -- format output file if exists
    if outfile then
        outfile = vformat(outfile)
    end

    -- format error file if exists
    if errfile then
        errfile = vformat(errfile)
    end

    -- open process
    local proc = process.open(command, outfile, errfile)
    if not proc then
        raise("open process(%s) failed!", command)
    end

    -- ok
    return proc
end

-- open process with arguments
function sandbox_process.openv(argv, outfile, errfile) 

    -- check
    assert(argv)

    -- format output file if exists
    if outfile then
        outfile = vformat(outfile)
    end

    -- format error file if exists
    if errfile then
        errfile = vformat(errfile)
    end

    -- open process
    local proc = process.openv(argv, outfile, errfile)
    if not proc then
        raise("openv process(%s) failed!", table.concat(argv, " "))
    end

    -- ok
    return proc
end

-- close process
function sandbox_process.close(proc)

    -- check
    assert(proc)

    -- close it
    process.close(proc)
end

-- wait process
function sandbox_process.wait(proc, timeout)

    -- check
    assert(proc)

    -- wait it
    local ok, status = process.wait(proc, timeout)
    if ok < 0 then
        raise("wait process failed(%d)", ok)
    end

    -- timeout or finished
    return ok, status
end

-- wait processes
function sandbox_process.waitlist(processes, timeout)

    -- check
    assert(processes)

    -- wait them
    local count, infos = process.waitlist(processes, timeout)
    if count < 0 then
        raise("wait processes(%d) failed(%d)", #processes, count)
    end

    -- check infos
    assert(infos and count == #infos)

    -- timeout or finished
    return count, infos
end

-- return module
return sandbox_process

