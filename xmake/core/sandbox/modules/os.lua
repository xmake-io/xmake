--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        os.lua
--

-- load modules
local io        = require("base/io")
local os        = require("base/os")
local utils     = require("base/utils")
local xmake     = require("base/xmake")
local option    = require("base/option")
local semver    = require("base/semver")
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
sandbox_os.setenvp      = os.setenvp
sandbox_os.addenvp      = os.addenvp
sandbox_os.getenvs      = os.getenvs
sandbox_os.pbpaste      = os.pbpaste
sandbox_os.pbcopy       = os.pbcopy
sandbox_os.cpuinfo      = os.cpuinfo
sandbox_os.emptydir     = os.emptydir
sandbox_os.filesize     = os.filesize
sandbox_os.workingdir   = os.workingdir
sandbox_os.programdir   = os.programdir
sandbox_os.programfile  = os.programfile
sandbox_os.projectdir   = os.projectdir
sandbox_os.projectfile  = os.projectfile
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

-- link file or directory to the new symfile
function sandbox_os.ln(filedir, symfile)
    local ok, errors = os.ln(filedir, symfile)
    if not ok then
        os.raise(errors)
    end
end

-- copy file or directory with the verbose info
function sandbox_os.vcp(...)
    if option.get("verbose") then
        local srcfile, dstfile = ...
        if srcfile and dstfile then
            utils.cprint("${dim}> copy %s to %s ..", srcfile, dstfile)
        end
    end
    return sandbox_os.cp(...)
end 

-- move file or directory with the verbose info
function sandbox_os.vmv(...)
    if option.get("verbose") then
        local srcfile, dstfile = ...
        if srcfile and dstfile then
            utils.cprint("${dim}> move %s to %s ..", srcfile, dstfile)
        end
    end
    return sandbox_os.mv(...)
end 

-- remove file or directory with the verbose info
function sandbox_os.vrm(...)
    if option.get("verbose") then
        local file = ...
        if file then
            utils.cprint("${dim}> remove %s ..", file)
        end
    end
    return sandbox_os.rm(...)
end 

-- link file or directory with the verbose info
function sandbox_os.vln(...)
    if option.get("verbose") then
        local srcfile, dstfile = ...
        if srcfile and dstfile then
            utils.cprint("${dim}> link %s to %s ..", srcfile, dstfile)
        end
    end
    return sandbox_os.ln(...)
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
        print(vformat(program) .. " " .. table.concat(argv, " "))
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
        os.raise({errors = errors, stderr = errdata, stdout = outdata})
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
        os.raise({errors = errors, stderr = errdata, stdout = outdata})
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
    -- e.g. 
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
    opt = opt or {}
    local ok = os.execv(program, argv, opt)
    if ok ~= 0 and not opt.try then
        if argv ~= nil then
            os.raise("execv(%s %s) failed(%d)!", program, table.concat(argv, ' '), ok)
        else
            os.raise("execv(%s) failed(%d)!", program, ok)
        end
    end
    return ok
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
    assert(dirpath)
    return os.isdir(vformat(dirpath))
end

-- is file?
function sandbox_os.isfile(filepath)
    assert(filepath)
    return os.isfile(vformat(filepath))
end

-- is symlink?
function sandbox_os.islink(filepath)
    assert(filepath)
    return os.islink(vformat(filepath))
end

-- is execute program?
function sandbox_os.isexec(filepath)
    assert(filepath)
    return os.isexec(vformat(filepath))
end

-- exists file or directory?
function sandbox_os.exists(filedir)
    assert(filedir)
    return os.exists(vformat(filedir))
end

-- read the content of symlink
function sandbox_os.readlink(symlink)
    local result = os.readlink(symlink)
    if not result then
        os.raise("cannot read link(%s)", symlink)
    end
    return result
end

-- get xmake version
function sandbox_os.xmakever()

    -- fill cache
    if sandbox_os._XMAKEVER == nil then
        -- get xmakever
        local xmakever = semver.new(xmake._VERSION_SHORT)
        -- save to cache
        sandbox_os._XMAKEVER = xmakever or false
    end

    -- done
    return sandbox_os._XMAKEVER or nil
end

-- return module
return sandbox_os

