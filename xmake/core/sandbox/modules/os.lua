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
-- @file        os.lua
--

-- load modules
local io        = require("base/io")
local os        = require("base/os")
local utils     = require("base/utils")
local sandbox   = require("sandbox/sandbox")
local vformat   = require("sandbox/modules/vformat")

-- define module
local sandbox_os = sandbox_os or {}

-- inherit some builtin interfaces
sandbox_os.date     = os.date
sandbox_os.time     = os.time
sandbox_os.mtime    = os.mtime
sandbox_os.mclock   = os.mclock

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
function sandbox_os.rm(file_or_dir, rm_superdir_if_empty)
    
    -- check
    assert(file_or_dir)

    -- format it first
    file_or_dir = vformat(file_or_dir)

    -- done
    local ok, errors = os.rm(file_or_dir, rm_superdir_if_empty)
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

    -- the previous directory
    local olddir = os.curdir()

    -- done
    local ok, errors = os.cd(dir)
    if not ok then
        os.raise(errors)
    end

    -- ok
    return olddir
end

-- create directory
function sandbox_os.mkdir(dir)
    
    -- check
    assert(dir)

    -- format it first
    dir = vformat(dir)

    -- done
    if not os.isdir(dir) then
        if not os.mkdir(dir) then
            os.raise("create directory: %s failed!", dir)
        end
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

-- get the temporary file
function sandbox_os.tmpfile()
   
    -- get it
    local tmpfile = os.tmpfile()
    assert(tmpfile)

    -- ok
    return tmpfile
end

-- get the tools directory
function sandbox_os.toolsdir()
   
    -- get it
    return xmake._TOOLS_DIR
end

-- get the program directory
function sandbox_os.programdir()
   
    -- get it
    return xmake._PROGRAM_DIR
end

-- get the script directory
function sandbox_os.scriptdir()
  
    -- get the current sandbox instance
    local instance = sandbox.instance()
    assert(instance)

    -- the root directory for this sandbox script
    local rootdir = instance:rootdir()
    assert(rootdir)

    -- ok
    return rootdir
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

-- run shell with arguments list
function sandbox_os.runv(shellname, argv)

    -- make shellname
    shellname = vformat(shellname)

    -- run it
    local ok, errors = os.runv(shellname, argv)
    if not ok then
        os.raise(errors)
    end
end

-- run shell and return output and error data
function sandbox_os.iorun(cmd, ...)

    -- make command
    cmd = vformat(cmd, ...)

    -- run it
    local ok, outdata, errdata = os.iorun(cmd)
    if not ok then
        os.raise((outdata or "") .. (errdata or ""))
    end

    -- ok
    return outdata, errdata
end

-- run shell and return output and error data
function sandbox_os.iorunv(shellname, argv)

    -- make shellname
    shellname = vformat(shellname)

    -- run it
    local ok, outdata, errdata = os.iorunv(shellname, argv)
    if not ok then
        os.raise(errdata)
    end

    -- ok
    return outdata, errdata
end

-- execute shell 
function sandbox_os.exec(cmd, ...)

    -- make command
    cmd = vformat(cmd, ...)

    -- run it
    local ok = os.exec(cmd)
    if ok ~= 0 then
        os.raise("exec(%s) failed(%d)!", cmd, ok)
    end
end

-- execute shell with arguments list
function sandbox_os.execv(shellname, argv)

    -- make shellname
    shellname = vformat(shellname)

    -- run it
    local ok = os.execv(shellname, argv)
    if ok ~= 0 then
        if argv ~= nil then
            os.raise("execv(%s %s) failed(%d)!", shellname, table.concat(argv, ' '), ok)
        else
            os.raise("execv(%s) failed(%d)!", shellname, ok)
        end
    end
end

-- match files or directories
function sandbox_os.match(pattern, findir, ...)

    -- check
    assert(pattern)

    -- format it first
    pattern = vformat(pattern, ...)

    -- match it
    return os.match(pattern, findir)
end

-- match files
function sandbox_os.files(pattern, ...)
    return sandbox_os.match(pattern, false, ...)
end

-- match directories
function sandbox_os.dirs(pattern, ...)
    return sandbox_os.match(pattern, true, ...)
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

-- is execute program?
function sandbox_os.isexec(filepath)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    return os.isexec(filepath)
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

-- get the envirnoment variables
function sandbox_os.getenv(name)

    -- check
    assert(name)

    -- get it
    return os.getenv(name)
end

-- set the envirnoment variables
function sandbox_os.setenv(name, values)

    -- check
    assert(name)

    -- set it
    os.setenv(name, values)
end

-- make a new uuid
function sandbox_os.uuid(name)

    -- make it
    local uuid = os.uuid(name)
    assert(uuid)

    -- ok?
    return uuid
end

-- return module
return sandbox_os

