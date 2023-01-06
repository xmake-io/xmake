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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
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
local scheduler = require("base/scheduler")
local sandbox   = require("sandbox/sandbox")
local vformat   = require("sandbox/modules/vformat")

-- define module
local sandbox_os = sandbox_os or {}

-- inherit some builtin interfaces
sandbox_os.shell        = os.shell
sandbox_os.term         = os.term
sandbox_os.host         = os.host
sandbox_os.arch         = os.arch
sandbox_os.subhost      = os.subhost
sandbox_os.subarch      = os.subarch
sandbox_os.syserror     = os.syserror
sandbox_os.strerror     = os.strerror
sandbox_os.exit         = os.exit
sandbox_os.date         = os.date
sandbox_os.time         = os.time
sandbox_os.args         = os.args
sandbox_os.args         = os.args
sandbox_os.argv         = os.argv
sandbox_os.mtime        = os.mtime
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
sandbox_os.setenvs      = os.setenvs
sandbox_os.addenvs      = os.addenvs
sandbox_os.joinenvs     = os.joinenvs
sandbox_os.pbpaste      = os.pbpaste
sandbox_os.pbcopy       = os.pbcopy
sandbox_os.cpuinfo      = os.cpuinfo
sandbox_os.meminfo      = os.meminfo
sandbox_os.default_njob = os.default_njob
sandbox_os.emptydir     = os.emptydir
sandbox_os.filesize     = os.filesize
sandbox_os.features     = os.features
sandbox_os.workingdir   = os.workingdir
sandbox_os.programdir   = os.programdir
sandbox_os.programfile  = os.programfile
sandbox_os.projectdir   = os.projectdir
sandbox_os.projectfile  = os.projectfile
sandbox_os.getwinsize   = os.getwinsize
sandbox_os.getpid       = os.getpid

-- syserror code
sandbox_os.SYSERR_UNKNOWN     = os.SYSERR_UNKNOWN
sandbox_os.SYSERR_NONE        = os.SYSERR_NONE
sandbox_os.SYSERR_NOT_PERM    = os.SYSERR_NOT_PERM
sandbox_os.SYSERR_NOT_FILEDIR = os.SYSERR_NOT_FILEDIR
sandbox_os.SYSERR_NOT_ACCESS  = os.SYSERR_NOT_ACCESS

-- copy file or directory
function sandbox_os.cp(srcpath, dstpath, opt)
    assert(srcpath and dstpath)
    srcpath = tostring(srcpath)
    dstpath = tostring(dstpath)
    local ok, errors = os.cp(vformat(srcpath), vformat(dstpath), opt)
    if not ok then
        os.raise(errors)
    end
end

-- move file or directory
function sandbox_os.mv(srcpath, dstpath)
    assert(srcpath and dstpath)
    srcpath = tostring(srcpath)
    dstpath = tostring(dstpath)
    local ok, errors = os.mv(vformat(srcpath), vformat(dstpath))
    if not ok then
        os.raise(errors)
    end
end

-- remove files or directories
function sandbox_os.rm(filepath)
    assert(filepath)
    filepath = tostring(filepath)
    local ok, errors = os.rm(vformat(filepath))
    if not ok then
        os.raise(errors)
    end
end

-- link file or directory to the new symfile
function sandbox_os.ln(srcpath, dstpath)
    assert(srcpath and dstpath)
    srcpath = tostring(srcpath)
    dstpath = tostring(dstpath)
    local ok, errors = os.ln(vformat(srcpath), vformat(dstpath))
    if not ok then
        os.raise(errors)
    end
end

-- copy file or directory with the verbose info
function sandbox_os.vcp(srcpath, dstpath, opt)
    assert(srcpath and dstpath)
    if option.get("verbose") then
        utils.cprint("${dim}> copy %s to %s", srcpath, dstpath)
    end
    return sandbox_os.cp(srcpath, dstpath, opt)
end

-- move file or directory with the verbose info
function sandbox_os.vmv(srcpath, dstpath)
    assert(srcpath and dstpath)
    if option.get("verbose") then
        utils.cprint("${dim}> move %s to %s", srcpath, dstpath)
    end
    return sandbox_os.mv(srcpath, dstpath)
end

-- remove file or directory with the verbose info
function sandbox_os.vrm(filepath)
    assert(filepath)
    if option.get("verbose") then
        utils.cprint("${dim}> remove %s", filepath)
    end
    return sandbox_os.rm(filepath)
end

-- link file or directory with the verbose info
function sandbox_os.vln(srcpath, dstpath)
    assert(srcpath and dstpath)
    if option.get("verbose") then
        utils.cprint("${dim}> link %s to %s", srcpath, dstpath)
    end
    return sandbox_os.ln(srcpath, dstpath)
end

-- try to copy file or directory
function sandbox_os.trycp(srcpath, dstpath, opt)
    assert(srcpath and dstpath)
    return os.cp(vformat(srcpath), vformat(dstpath), opt)
end

-- try to move file or directory
function sandbox_os.trymv(srcpath, dstpath)
    assert(srcpath and dstpath)
    return os.mv(vformat(srcpath), vformat(dstpath))
end

-- try to remove files or directories
function sandbox_os.tryrm(filepath)
    assert(filepath)
    return os.rm(vformat(filepath))
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

-- touch file or directory
function sandbox_os.touch(filepath, opt)
    assert(filepath)
    local ok, errors = os.touch(vformat(filepath), opt)
    if not ok then
        os.raise(errors)
    end
end

-- create directories
function sandbox_os.mkdir(dir)
    assert(dir)
    local ok, errors = os.mkdir(vformat(dir))
    if not ok then
        os.raise(errors)
    end
end

-- remove directories
function sandbox_os.rmdir(dir)
    assert(dir)
    local ok, errors = os.rmdir(vformat(dir))
    if not ok then
        os.raise(errors)
    end
end

-- get the current directory
function sandbox_os.curdir()
    return assert(os.curdir())
end

-- get the temporary directory
function sandbox_os.tmpdir(opt)
    return assert(os.tmpdir(opt))
end

-- get the temporary file
function sandbox_os.tmpfile(key, opt)
    return assert(os.tmpfile(key, opt))
end

-- get the script directory
function sandbox_os.scriptdir()
    local instance = sandbox.instance()
    local rootdir = instance:rootdir()
    assert(rootdir)
    return rootdir
end

-- quietly run command
function sandbox_os.run(cmd, ...)
    cmd = vformat(cmd, ...)
    local ok, errors = os.run(cmd)
    if not ok then
        os.raise(errors)
    end
end

-- quietly run command with arguments list
function sandbox_os.runv(program, argv, opt)
    program = vformat(program)
    local ok, errors = os.runv(program, argv, opt)
    if not ok then
        os.raise(errors)
    end
end

-- quietly run command and echo verbose info if [-v|--verbose] option is enabled
function sandbox_os.vrun(cmd, ...)
    if option.get("verbose") then
        print(vformat(cmd, ...))
    end
    (option.get("verbose") and sandbox_os.exec or sandbox_os.run)(cmd, ...)
end

-- quietly run command with arguments list and echo verbose info if [-v|--verbose] option is enabled
function sandbox_os.vrunv(program, argv, opt)
    if option.get("verbose") then
        print(vformat(program) .. " " .. sandbox_os.args(argv))
    end
    if not (opt and opt.dryrun) then
        (option.get("verbose") and sandbox_os.execv or sandbox_os.runv)(program, argv, opt)
    end
end

-- run command and return output and error data
function sandbox_os.iorun(cmd, ...)
    cmd = vformat(cmd, ...)
    local ok, outdata, errdata, errors = os.iorun(cmd)
    if not ok then
        if not errors then
            errors = errdata or ""
            if #errors:trim() == 0 then
                errors = outdata or ""
            end
        end
        os.raise({errors = errors, stderr = errdata, stdout = outdata})
    end
    return outdata, errdata
end

-- run command and return output and error data
function sandbox_os.iorunv(program, argv, opt)
    program = vformat(program)
    local ok, outdata, errdata, errors = os.iorunv(program, argv, opt)
    if not ok then
        if not errors then
            errors = errdata or ""
            if #errors:trim() == 0 then
                errors = outdata or ""
            end
        end
        os.raise({errors = errors, stderr = errdata, stdout = outdata})
    end
    return outdata, errdata
end

-- execute command
function sandbox_os.exec(cmd, ...)
    cmd = vformat(cmd, ...)
    local ok, errors = os.exec(cmd)
    if ok ~= 0 then
        if ok ~= nil then
            errors = string.format("exec(%s) failed(%d)", cmd, ok)
        else
            errors = string.format("cannot exec(%s), %s", cmd, errors and errors or "unknown reason")
        end
        os.raise(errors)
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
    local ok, errors = os.execv(program, argv, opt)
    if ok ~= 0 and not opt.try then

        -- get command
        local cmd = program
        if argv then
            cmd = cmd .. " " .. os.args(argv)
        end

        -- get errors
        if ok ~= nil then
            errors = string.format("execv(%s) failed(%d)", cmd, ok)
        else
            errors = string.format("cannot execv(%s), %s", cmd, errors and errors or "unknown reason")
        end
        os.raise(errors)
    end

    -- we need return results if opt.try is enabled
    return ok, errors
end

-- execute command and echo verbose info if [-v|--verbose] option is enabled
function sandbox_os.vexec(cmd, ...)

    -- echo command
    if option.get("verbose") then
        utils.cprint("${color.dump.string}" .. vformat(cmd, ...))
    end

    -- run it
    sandbox_os.exec(cmd, ...)
end

-- execute command with arguments list and echo verbose info if [-v|--verbose] option is enabled
function sandbox_os.vexecv(program, argv, opt)

    -- echo command
    if option.get("verbose") then
        utils.cprint("${color.dump.string}" .. vformat(program) .. " " .. sandbox_os.args(argv))
    end

    -- run it
    if not (opt and opt.dryrun) then
        return sandbox_os.execv(program, argv, opt)
    else
        return 0
    end
end

-- match files or directories
function sandbox_os.match(pattern, mode, callback)
    return os.match(vformat(tostring(pattern)), mode, callback)
end

-- match directories
function sandbox_os.dirs(pattern, callback)
    return (sandbox_os.match(pattern, 'd', callback))
end

-- match files
function sandbox_os.files(pattern, callback)
    return (sandbox_os.match(pattern, 'f', callback))
end

-- match files and directories
function sandbox_os.filedirs(pattern, callback)
    return (sandbox_os.match(pattern, 'a', callback))
end

-- is directory?
function sandbox_os.isdir(dirpath)
    assert(dirpath)
    dirpath = tostring(dirpath)
    return os.isdir(vformat(dirpath))
end

-- is file?
function sandbox_os.isfile(filepath)
    assert(filepath)
    filepath = tostring(filepath)
    return os.isfile(vformat(filepath))
end

-- is symlink?
function sandbox_os.islink(filepath)
    assert(filepath)
    filepath = tostring(filepath)
    return os.islink(vformat(filepath))
end

-- is execute program?
function sandbox_os.isexec(filepath)
    assert(filepath)
    filepath = tostring(filepath)
    return os.isexec(vformat(filepath))
end

-- exists file or directory?
function sandbox_os.exists(filedir)
    assert(filedir)
    filedir = tostring(filedir)
    return os.exists(vformat(filedir))
end

-- read the content of symlink
function sandbox_os.readlink(symlink)
    local result = os.readlink(tostring(symlink))
    if not result then
        os.raise("cannot read link(%s)", symlink)
    end
    return result
end

-- sleep (support in coroutine)
function sandbox_os.sleep(ms)
    if scheduler:co_running() then
        local ok, errors = scheduler:co_sleep(ms)
        if not ok then
            raise(errors)
        end
    else
        os.sleep(ms)
    end
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

