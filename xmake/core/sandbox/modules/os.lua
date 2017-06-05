--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        os.lua
--

-- load modules
local io        = require("base/io")
local os        = require("base/os")
local utils     = require("base/utils")
local option    = require("base/option")
local sandbox   = require("sandbox/sandbox")
local vformat   = require("sandbox/modules/vformat")

-- define module
local sandbox_os = sandbox_os or {}

-- inherit some builtin interfaces
sandbox_os.host         = os.host
sandbox_os.arch         = os.arch
sandbox_os.exit         = os.exit
sandbox_os.date         = os.date
sandbox_os.time         = os.time
sandbox_os.argv         = os.argv
sandbox_os.argw         = os.argw
sandbox_os.mtime        = os.mtime
sandbox_os.sleep        = os.sleep
sandbox_os.mclock       = os.mclock
sandbox_os.nuldev       = os.nuldev
sandbox_os.emptydir     = os.emptydir
sandbox_os.programdir   = os.programdir
sandbox_os.programfile  = os.programfile
sandbox_os.versioninfo  = os.versioninfo

-- copy file or directory
function sandbox_os.cp(...)
    
    -- format arguments
    local args = {}
    for _, arg in ipairs({...}) do
        table.insert(args, vformat(arg))
    end

    -- done
    local ok, errors = os.cp(unpack(args))
    if not ok then
        os.raise(errors)
    end
end

-- move file or directory
function sandbox_os.mv(...)
    
    -- format arguments
    local args = {}
    for _, arg in ipairs({...}) do
        table.insert(args, vformat(arg))
    end

    -- done
    local ok, errors = os.mv(unpack(args))
    if not ok then
        os.raise(errors)
    end
end

-- remove files or directories
function sandbox_os.rm(...)
    
    -- format arguments
    local args = {}
    for _, arg in ipairs({...}) do
        table.insert(args, vformat(arg))
    end

    -- remove it
    local ok, errors = os.rm(unpack(args))
    if not ok then
        os.raise(errors)
    end
end

-- try to copy file or directory
function sandbox_os.trycp(...)
    
    -- format arguments
    local args = {}
    for _, arg in ipairs({...}) do
        table.insert(args, vformat(arg))
    end

    -- done
    return os.cp(unpack(args))
end

-- try to move file or directory
function sandbox_os.trymv(...)
    
    -- format arguments
    local args = {}
    for _, arg in ipairs({...}) do
        table.insert(args, vformat(arg))
    end

    -- done
    return os.mv(unpack(args))
end

-- try to remove files or directories
function sandbox_os.tryrm(...)
    
    -- format arguments
    local args = {}
    for _, arg in ipairs({...}) do
        table.insert(args, vformat(arg))
    end

    -- remove it
    return os.rm(unpack(args))
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

-- create directories
function sandbox_os.mkdir(...)
   
    -- format arguments
    local args = {}
    for _, arg in ipairs({...}) do
        table.insert(args, vformat(arg))
    end

    -- done
    local ok, errors = os.mkdir(unpack(args))
    if not ok then
        os.raise(errors)
    end
end

-- remove directories
function sandbox_os.rmdir(...)
    
    -- format arguments
    local args = {}
    for _, arg in ipairs({...}) do
        table.insert(args, vformat(arg))
    end

    -- done
    local ok, errors = os.rmdir(unpack(args))
    if not ok then
        os.raise(errors)
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

-- quietly run shell
function sandbox_os.run(cmd, ...)

    -- make command
    cmd = vformat(cmd, ...)

    -- run it
    local ok, errors = os.run(cmd)
    if not ok then
        os.raise(errors)
    end
end

-- quietly run shell with arguments list
function sandbox_os.runv(shellname, argv)

    -- make shellname
    shellname = vformat(shellname)

    -- run it
    local ok, errors = os.runv(shellname, argv)
    if not ok then
        os.raise(errors)
    end
end

-- quietly run shell and echo verbose info if [-v|--verbose] option is enabled
function sandbox_os.vrun(cmd, ...)

    -- echo command
    if option.get("verbose") then
        print(vformat(cmd, ...))
    end

    -- run it
    utils.ifelse(option.get("verbose"), sandbox_os.exec, sandbox_os.run)(cmd, ...)  
end

-- quietly run shell with arguments list and echo verbose info if [-v|--verbose] option is enabled
function sandbox_os.vrunv(shellname, argv)

    -- echo command
    if option.get("verbose") then
        print(vformat(shellname), table.concat(argv, " "))
    end

    -- run it
    utils.ifelse(option.get("verbose"), sandbox_os.execv, sandbox_os.runv)(shellname, argv)  
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
function sandbox_os.match(pattern, mode, ...)

    -- check
    assert(pattern)

    -- format it first
    pattern = vformat(pattern, ...)

    -- match it
    return os.match(pattern, mode)
end

-- match directories
function sandbox_os.dirs(pattern, ...)
    return sandbox_os.match(pattern, 'd', ...)
end

-- match files
function sandbox_os.files(pattern, ...)
    return sandbox_os.match(pattern, 'f', ...)
end

-- match files and directories
function sandbox_os.filedirs(pattern, ...)
    return sandbox_os.match(pattern, 'a', ...)
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

-- get values of the envirnoment variable 
function sandbox_os.getenv(name)

    -- check
    assert(name)

    -- get it
    return os.getenv(name)
end

-- set values to the envirnoment variable
function sandbox_os.setenv(name, ...)

    -- check
    assert(name)

    -- set it
    os.setenv(name, ...)
end

-- add values to the envirnoment variable
function sandbox_os.addenv(name, ...)

    -- check
    assert(name)

    -- add it
    os.addenv(name, ...)
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

