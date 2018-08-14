--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
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
sandbox_os.args         = os.args
sandbox_os.argv         = os.argv
sandbox_os.argw         = os.argw
sandbox_os.mtime        = os.mtime
sandbox_os.sleep        = os.sleep
sandbox_os.raise        = os.raise
sandbox_os.fscase       = os.fscase
sandbox_os.isroot       = os.isroot
sandbox_os.mclock       = os.mclock
sandbox_os.nuldev       = os.nuldev
sandbox_os.getenv       = os.getenv
sandbox_os.setenv       = os.setenv
sandbox_os.addenv       = os.addenv
sandbox_os.pbpaste      = os.pbpaste
sandbox_os.pbcopy       = os.pbcopy
sandbox_os.emptydir     = os.emptydir
sandbox_os.filesize     = os.filesize
sandbox_os.workingdir   = os.workingdir
sandbox_os.programdir   = os.programdir
sandbox_os.programfile  = os.programfile
sandbox_os.projectdir   = os.projectdir
sandbox_os.projectfile  = os.projectfile
sandbox_os.versioninfo  = os.versioninfo
sandbox_os.getwinsize   = os.getwinsize
sandbox_os.user_agent   = os.user_agent

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

    -- enter this directory
    local oldir, errors = os.cd(dir)
    if not oldir then
        os.raise(errors)
    end

    -- ok
    return oldir
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
    return assert(os.curdir())
end

-- get the temporary directory
function sandbox_os.tmpdir()
    return assert(os.tmpdir())
end

-- get the temporary file
function sandbox_os.tmpfile(key)
    return assert(os.tmpfile(key))
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

-- quietly run command
function sandbox_os.run(cmd, ...)

    -- make command
    cmd = vformat(cmd, ...)

    -- run it
    local ok, errors = os.run(cmd)
    if not ok then
        os.raise(errors)
    end
end

-- quietly run command with arguments list
function sandbox_os.runv(program, argv, opt)

    -- make program
    program = vformat(program)

    -- run it
    local ok, errors = os.runv(program, argv, opt)
    if not ok then
        os.raise(errors)
    end
end

-- quietly run command and echo verbose info if [-v|--verbose] option is enabled
function sandbox_os.vrun(cmd, ...)

    -- echo command
    if option.get("verbose") then
        print(vformat(cmd, ...))
    end

    -- run it
    utils.ifelse(option.get("verbose"), sandbox_os.exec, sandbox_os.run)(cmd, ...)  
end

-- quietly run command with arguments list and echo verbose info if [-v|--verbose] option is enabled
function sandbox_os.vrunv(program, argv, opt)

    -- echo command
    if option.get("verbose") then
        print(vformat(program), table.concat(argv, " "))
    end

    -- run it
    utils.ifelse(option.get("verbose"), sandbox_os.execv, sandbox_os.runv)(program, argv, opt)  
end

-- run command and return output and error data
function sandbox_os.iorun(cmd, ...)

    -- make command
    cmd = vformat(cmd, ...)

    -- run it
    local ok, outdata, errdata = os.iorun(cmd)
    if not ok then
        local errors = errdata or ""
        if #errors:trim() == 0 then
            errors = outdata or ""
        end
        os.raise(errors)
    end

    -- ok
    return outdata, errdata
end

-- run command and return output and error data
function sandbox_os.iorunv(program, argv, opt)

    -- make program
    program = vformat(program)

    -- run it
    local ok, outdata, errdata = os.iorunv(program, argv, opt)
    if not ok then
        local errors = errdata or ""
        if #errors:trim() == 0 then
            errors = outdata or ""
        end
        os.raise(errors)
    end

    -- ok
    return outdata, errdata
end

-- execute command 
function sandbox_os.exec(cmd, ...)

    -- make command
    cmd = vformat(cmd, ...)

    -- run it
    local ok = os.exec(cmd)
    if ok ~= 0 then
        os.raise("exec(%s) failed(%d)!", cmd, ok)
    end
end

-- execute command with arguments list
function sandbox_os.execv(program, argv, opt)

    -- make program
    program = vformat(program)

    -- flush io buffer first for fixing redirect io output order
    --
    -- .e.g 
    --
    -- xmake run > /tmp/a
    --   print("xxx1")
    --   os.exec("echo xxx2")
    --
    -- cat /tmp/a
    --   xxx2
    --   xxx1
    -- 
    io.flush()

    -- run it
    local ok = os.execv(program, argv, opt)
    if ok ~= 0 then
        if argv ~= nil then
            os.raise("execv(%s %s) failed(%d)!", program, table.concat(argv, ' '), ok)
        else
            os.raise("execv(%s) failed(%d)!", program, ok)
        end
    end
end

-- match files or directories
function sandbox_os.match(pattern, mode, callback)
    return os.match(vformat(pattern), mode, callback)
end

-- match directories
function sandbox_os.dirs(pattern, callback)
    return sandbox_os.match(pattern, 'd', callback)
end

-- match files
function sandbox_os.files(pattern, callback)
    return sandbox_os.match(pattern, 'f', callback)
end

-- match files and directories
function sandbox_os.filedirs(pattern, callback)
    return sandbox_os.match(pattern, 'a', callback)
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

-- return module
return sandbox_os

