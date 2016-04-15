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
-- @file        os.lua
--

-- load modules
local io        = require("base/io")
local os        = require("base/os")
local utils     = require("base/utils")
local vformat   = require("sandbox/modules/vformat")

-- define module
local sandbox_os = sandbox_os or {}

-- inherit some builtin interfaces
sandbox_os.date = os.date
sandbox_os.time = os.time

-- copy file or directory
function sandbox_os.cp(src, dst)
    
    -- check
    assert(src and dst)

    -- format it first
    src = vformat(src)
    dst = vformat(dst)

    -- done
    local ok, errors = os.cp(src, dst)
    if not ok then
        os.raise(errors)
    end

end

-- move file or directory
function sandbox_os.mv(src, dst)
    
    -- check
    assert(src and dst)

    -- format it first
    src = vformat(src)
    dst = vformat(dst)

    -- done
    local ok, errors = os.mv(src, dst)
    if not ok then
        os.raise(errors)
    end

end

-- remove file or directory
function sandbox_os.rm(file_or_dir, emptydir)
    
    -- check
    assert(file_or_dir)

    -- format it first
    file_or_dir = vformat(file_or_dir)

    -- done
    local ok, errors = os.rm(file_or_dir, emptydir)
    if not ok then
        os.raise(errors)
    end

end

-- change to directory
function sandbox_os.cd(dir)

    -- check
    assert(dir)

    -- format it first
    dir = vformat(dir)

    -- done
    local ok, errors = os.cd(dir)
    if not ok then
        os.raise(errors)
    end

end

-- create directory
function sandbox_os.mkdir(dir)
    
    -- check
    assert(dir)

    -- format it first
    dir = vformat(dir)

    -- done
    if not os.mkdir(dir) then
        os.raise("create directory: %s failed!", dir)
    end

end

-- remove directory
function sandbox_os.rmdir(dir)
    
    -- check
    assert(dir)

    -- format it first
    dir = vformat(dir)

    -- done
    if os.isdir(dir) then
        if not os.rmdir(dir) then
            os.raise("remove directory: %s failed!", dir)
        end
    end

end

-- get the current directory
function sandbox_os.curdir()
   
    -- get it
    local curdir = os.curdir()
    assert(curdir)

    -- ok
    return curdir
end

-- get the temporary directory
function sandbox_os.tmpdir()
   
    -- get it
    local tmpdir = os.tmpdir()
    assert(tmpdir)

    -- ok
    return tmpdir
end

-- run shell
function sandbox_os.run(cmd, ...)

    -- make command
    cmd = vformat(cmd, ...)

    -- run it
    local ok, errors = os.run(cmd)
    if not ok then
        os.raise(errors)
    end
end

-- execute shell
function sandbox_os.execute(cmd, ...)

    -- make command
    cmd = vformat(cmd, ...)

    -- run it
    return os.execute(cmd)
end

-- match files or directories
function sandbox_os.match(pattern, findir)

    -- check
    assert(pattern)

    -- format it first
    pattern = vformat(pattern)

    -- match it
    return os.match(pattern, findir)
end

-- is directory?
function sandbox_os.isdir(dirpath)

    -- check
    assert(dirpath)

    -- format it first
    dirpath = vformat(dirpath)

    -- done
    return os.isdir(dirpath)
end

-- is directory?
function sandbox_os.isfile(filepath)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    return os.isfile(filepath)
end

-- exists file or directory?
function sandbox_os.exists(file_or_dir)

    -- check
    assert(file_or_dir)

    -- format it first
    file_or_dir = vformat(file_or_dir)

    -- done
    return os.exists(file_or_dir)
end

-- raise an exception and abort the current script
function sandbox_os.raise(msg, ...)

    -- raise it
    os.raise(msg, ...)
end

-- get the system host
function sandbox_os.host()

    -- get it
    return xmake._HOST
end

-- get the system architecture
function sandbox_os.arch()

    -- get it
    return xmake._ARCH
end

-- get the system null device
function sandbox_os.nuldev()

    -- get it
    return xmake._NULDEV
end


-- return module
return sandbox_os

