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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        os.lua
--

-- define module
local os = os or {}

-- load modules
local io        = require("base/io")
local log       = require("base/log")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")
local process   = require("base/process")

-- save original interfaces
os._uid      = os._uid or os.uid
os._gid      = os._gid or os.gid
os._getpid   = os._getpid or os.getpid
os._exit     = os._exit or os.exit
os._mkdir    = os._mkdir or os.mkdir
os._rmdir    = os._rmdir or os.rmdir
os._touch    = os._touch or os.touch
os._tmpdir   = os._tmpdir or os.tmpdir
os._curdir   = os._curdir or os.curdir
os._fscase   = os._fscase or os.fscase
os._setenv   = os._setenv or os.setenv
os._getenvs  = os._getenvs or os.getenvs
os._cpuinfo  = os._cpuinfo or os.cpuinfo
os._meminfo  = os._meminfo or os.meminfo
os._readlink = os._readlink or os.readlink
os._access   = os._access or os.access

-- syserror code
os.SYSERR_UNKNOWN     = -1
os.SYSERR_NONE        = 0
os.SYSERR_NOT_PERM    = 1
os.SYSERR_NOT_FILEDIR = 2
os.SYSERR_NOT_ACCESS  = 3

-- get the async task
function os._async_task()
    local async_task = os._ASYNC_TASK
    if async_task == nil then
        async_task = require("base/private/async_task")
        os._ASYNC_TASK = async_task
    end
    return async_task
end

-- copy single file or directory
function os._cp(src, dst, rootdir, opt)
    opt = opt or {}
    assert(src and dst)

    -- reserve the source directory structure if opt.rootdir is given
    if rootdir then
        if not path.is_absolute(src) then
            src = path.absolute(src)
        end
        if not src:startswith(rootdir) then
            return false, string.format("cannot copy file %s to %s, invalid rootdir(%s)", src, dst, rootdir)
        end
    end

    -- is file or link?
    local symlink = opt.symlink
    local writeable = opt.writeable
    local copy_if_different = opt.copy_if_different
    if os.isfile(src) or (symlink and os.islink(src)) then

        -- the destination is directory? append the filename
        if os.isdir(dst) or path.islastsep(dst) then
            if rootdir then
                dst = path.join(dst, path.relative(src, rootdir))
            else
                dst = path.join(dst, path.filename(src))
            end
        end

        -- copy or link file
        if opt.force and os.isfile(dst) then
            os.rmfile(dst)
        end
        if not os.cpfile(src, dst, symlink, writeable, copy_if_different) then
            local errors = os.strerror()
            if symlink and os.islink(src) then
                local reallink = os.readlink(src)
                return false, string.format("cannot link %s(%s) to %s, %s", src, reallink, dst, errors)
            else
                return false, string.format("cannot copy file %s to %s, %s", src, dst, errors)
            end
        end
    -- is directory?
    elseif os.isdir(src) then

        -- the destination directory exists? append the filename
        if os.isdir(dst) or path.islastsep(dst) then
            if rootdir then
                dst = path.join(dst, path.relative(src, rootdir))
            else
                dst = path.join(dst, path.filename(path.translate(src)))
            end
        end

        -- copy directory
        if not os.cpdir(src, dst, symlink, copy_if_different) then
            return false, string.format("cannot copy directory %s to %s,  %s", src, dst, os.strerror())
        end
    else
        return false, string.format("cannot copy file %s, file not found!", src)
    end
    return true
end

-- move single file or directory
function os._mv(src, dst, opt)
    opt = opt or {}
    assert(src and dst)

    if os.exists(src) then

        -- the destination directory exists? append the filename
        if os.isdir(dst) or path.islastsep(dst) then
            dst = path.join(dst, path.filename(path.translate(src)))
        end

        -- move file or directory
        if opt.force and os.isfile(dst) then
            os.rmfile(dst)
        end
        if not os.rename(src, dst) then
            return false, string.format("cannot move %s to %s %s", src, dst, os.strerror())
        end
    else
        return false, string.format("cannot move %s to %s, file %s not found!", src, dst, os.strerror())
    end
    return true
end

-- remove single file or directory
function os._rm(filedir)
    assert(filedir)

    -- is file or link?
    if os.isfile(filedir) or os.islink(filedir) then
        if not os.rmfile(filedir) then
            return false, string.format("cannot remove file %s %s", filedir, os.strerror())
        end
    -- is directory?
    elseif os.isdir(filedir) then
        if not os.rmdir(filedir) then
            return false, string.format("cannot remove directory %s %s", filedir, os.strerror())
        end
    end
    return true
end

-- remove empty parent directories of this file path
function os._rm_empty_parentdirs(filepath)
    local parentdir = path.directory(filepath)
    while parentdir and os.isdir(parentdir) and os.emptydir(parentdir) do
        local ok, errors = os._rm(parentdir)
        if not ok then
            return false, errors
        end
        parentdir = path.directory(parentdir)
    end
    return true
end

-- get the ramdisk root directory
-- https://github.com/xmake-io/xmake/issues/3408
function os._ramdir()
    local ramdir_root = os._ROOT_RAMDIR
    if ramdir_root == nil then
        ramdir_root = os.getenv("XMAKE_RAMDIR")
    end
    if ramdir_root == nil then
        ramdir_root = false
        os._ROOT_RAMDIR = ramdir_root
    end
    return ramdir_root or nil
end

-- set on change environments callback for scheduler
function os._sched_chenvs_set(envs)
    os._SCHED_CHENVS = envs
end

-- set on change directory callback for scheduler
function os._sched_chdir_set(chdir)
    os._SCHED_CHDIR = chdir
end

-- notify the current directory have been changed
function os._notify_curdir_changed()
    os._CURDIR = nil
    if os._SCHED_CHDIR then
        os._SCHED_CHDIR(os.curdir())
    end
end

-- notify envs have been changed
function os._notify_envs_changed(envs)
    if os._SCHED_CHENVS then
        os._SCHED_CHENVS(envs)
    end
end

-- the current host is belong to the given hosts?
function os._is_host(host, ...)
    if not host then
        return false
    end

    -- exists this host? and escape '-'
    for _, h in ipairs(table.join(...)) do
        if h and type(h) == "string" and host:find(h:gsub("%-", "%%-")) then
            return true
        end
    end
end

-- the current platform is belong to the given architectures?
function os._is_arch(arch, ...)
    if not arch then
        return false
    end

    -- exists this architecture? and escape '-'
    for _, a in ipairs(table.join(...)) do
        if a and type(a) == "string" and arch:find("^" .. a:gsub("%-", "%%-") .. "$") then
            return true
        end
    end
end

-- match wildcard files
function os._match_wildcard_pathes(v)
    if v:find("*", 1, true) then
        return (os.filedirs(v))
    end
    return v
end

-- split too long path environment variable for windows
--
-- @see https://github.com/xmake-io/xmake-repo/pull/489
-- https://stackoverflow.com/questions/34491244/environment-variable-is-too-large-on-windows-10
--
function os._deduplicate_pathenv(value)
    if value and #value > 4096 then
        local itemset = {}
        local results = {}
        for _, item in ipairs(path.splitenv(value)) do
            if not itemset[item] then
                table.insert(results, item)
                itemset[item] = true
            end
        end
        if #results > 0 then
            value = path.joinenv(results)
        end
    end
    return value
end

-- trace process for profile(stuck,trace)?
function os._is_tracing_process()
    local is_tracing = os._IS_TRACING_PROCESS
    if is_tracing == nil then
        local profile = os.getenv("XMAKE_PROFILE")
        if profile then
            profile = profile:trim()
            if profile == "trace" or profile == "stuck" then
                is_tracing = true
            end
        end
        is_tracing = is_tracing or false
        os._IS_TRACING_PROCESS = is_tracing
    end
    return is_tracing
end

-- profile process performance?
function os._is_profiling_process_perf()
    local is_profiling = os._IS_PROFILING_PROCESS_PERF
    if is_profiling == nil then
        local profile = os.getenv("XMAKE_PROFILE")
        if profile then
            profile = profile:trim()
            if profile == "perf:process" then
                is_profiling = true
            end
        end
        is_profiling = is_profiling or false
        os._IS_PROFILING_PROCESS_PERF = is_profiling
    end
    return is_profiling
end

-- run all exit callback
function os._run_exit_cbs(ok, errors)

    -- show process performance reports
    local profileperf = os._is_profiling_process_perf()
    if profileperf then
        if os._PROCESS_PROFILEINFO then
            local perfinfo = {}
            local totaltime = 0
            for runcmd, profileinfo in pairs(os._PROCESS_PROFILEINFO) do
                profileinfo.runcmd = runcmd
                totaltime = totaltime + profileinfo.totaltime
                table.insert(perfinfo, profileinfo)
            end
            table.sort(perfinfo, function (a, b) return a.totaltime > b.totaltime end)
            for _, profileinfo in ipairs(perfinfo) do
                local percent = (profileinfo.totaltime / totaltime) * 100
                if percent < 1 then
                    break
                end
                utils.print("%6.3f, %6.2f%%, %7d, %s", profileinfo.totaltime, percent, profileinfo.runcount, profileinfo.runcmd)
            end
        end
    end

    local exit_callbacks = os._EXIT_CALLBACKS
    if exit_callbacks then
        for _, cb in ipairs(exit_callbacks) do
            cb(ok, errors)
        end
    end
end

-- get shell path, e.g. sh, bash
function os._get_shell_path(opt)
    opt = opt or {}
    local setenvs = opt.setenvs or opt.envs or {}
    local addenvs = opt.addenvs or {}
    local paths = {}
    local p = setenvs.PATH
    if type(p) == "string" then
        p = path.splitenv(p)
    end
    if p then
        table.join2(paths, p)
    end
    p = addenvs.PATH
    if type(p) == "string" then
        p = path.splitenv(p)
    end
    if p then
        table.join2(paths, p)
    end
    for _, p in ipairs(paths) do
        for _, name in ipairs({"sh", "bash"}) do
            local filepath = path.join(p, name)
            if os.isexec(filepath) then
                return filepath
            end
        end
    end
end

-- match files or directories
--
-- @param pattern   the search pattern
--                  uses "*" to match any part of a file or directory name,
--                  uses "**" to recurse into subdirectories.
--
-- @param mode      the match mode
--                  - only find file:           'f' or false or nil
--                  - only find directory:      'd' or true
--                  - find file and directory:  'a'
-- @return          the result array and count
--
-- @code
-- local dirs, count = os.match("./src/*", true)
-- local files, count = os.match("./src/**.c")
-- local file = os.match("./src/test.c", 'f', function (filepath, isdir)
--                  return true   -- continue it
--                  return false  -- break it
--              end)
-- @endcode
--
function os.match(pattern, mode, opt)

    -- do it in the asynchronous task
    if type(opt) == "table" and opt.async and xmake.in_main_thread() then
        return os._async_task().match(pattern, mode)
    end

    -- extract callback
    local callback = type(opt) == "function" and opt or (type(opt) == "table" and opt.callback or nil)

    -- support path instance
    pattern = tostring(pattern)

    -- get the excludes
    local excludes = pattern:match("|.*$")
    if excludes then excludes = excludes:split("|", {plain = true}) end

    -- translate excludes
    if excludes then
        local _excludes = {}
        for _, exclude in ipairs(excludes) do
            exclude = path.translate(exclude)
            exclude = path.pattern(exclude)
            table.insert(_excludes, exclude)
        end
        excludes = _excludes
    end

    -- translate path and remove some repeat separators
    pattern = path.translate((pattern:gsub("|.*$", "")))

    -- translate mode
    if type(mode) == "string" then
        local modes = {a = -1, f = 0, d = 1}
        mode = modes[mode]
        assert(mode, "invalid match mode: %s", mode)
    elseif mode then
        mode = 1
    else
        mode = 0
    end

    -- match the single file without wildchard?
    if os.isfile(pattern) then
        if mode <= 0 then
            return {pattern}, 1
        else
            return {}, 0
        end
    -- match the single directory without wildchard?
    elseif os.isdir(pattern) then
        if (mode == -1 or mode == 1) then
            return {pattern}, 1
        else
            return {}, 0
        end
    end

    -- remove "./" or '.\\' prefix
    if pattern:sub(1, 2):find('%.[/\\]') then
        pattern = pattern:sub(3)
    end

    -- get the root directory
    local rootdir = pattern
    local startpos = pattern:find("*", 1, true)
    if startpos then
        rootdir = rootdir:sub(1, startpos - 1)
    end
    rootdir = path.directory(rootdir .. "_") -- patch '_' to avoid getting incorrect directory for `/foo/*`

    -- compute the recursion level
    --
    -- infinite recursion: src/**.c
    -- limit recursion level: src/*/*.c
    local recursion = 0
    if pattern:find("**", 1, true) then
        recursion = -1
    else
        -- "src/*/*.c" -> "*/" -> recursion level: 1
        -- "src/*/main.c" -> "*/" -> recursion level: 1
        -- "src/*/subdir/main.c" -> "*//" -> recursion level: 2
        if startpos then
            local _, seps = pattern:sub(startpos):gsub("[/\\]", "")
            if seps > 0 then
                recursion = seps
            end
        end
    end

    -- convert pattern to a lua pattern
    pattern = path.pattern(pattern)

    -- find it
    return os.find(rootdir, pattern, recursion, mode, excludes, callback)
end

-- match directories
--
-- @note only return {} without count to simplify code, e.g. table.unpack(os.dirs(""))
--
function os.dirs(pattern, opt)
    return (os.match(pattern, 'd', opt))
end

-- match files
function os.files(pattern, opt)
    return (os.match(pattern, 'f', opt))
end

-- match files and directories
function os.filedirs(pattern, opt)
    return (os.match(pattern, 'a', opt))
end

-- copy files or directories and we can reserve the source directory structure
--
-- @param srcpath   the source file path
-- @param dstpath   the destination file path
-- @param opt       the copy option. e.g. {rootdir, symlink, writeable, force, copy_if_different}
--
-- e.g. os.cp("src/**.h", "/tmp/", {rootdir = "src", symlink = true})
function os.cp(srcpath, dstpath, opt)

    -- check arguments
    if not srcpath or not dstpath then
        return false, string.format("invalid arguments!")
    end

    -- do it in the asynchronous task
    if opt and opt.async and xmake.in_main_thread() then
        return os._async_task().cp(srcpath, dstpath, {detach = opt.detach})
    end

    -- reserve the source directory structure if opt.rootdir is given
    local rootdir = opt and opt.rootdir
    if rootdir then
        rootdir = tostring(rootdir)
        if not path.is_absolute(rootdir) then
            rootdir = path.absolute(rootdir)
        end
    end

    -- copy files or directories
    srcpath = tostring(srcpath)
    dstpath = tostring(dstpath)
    local srcpathes = os._match_wildcard_pathes(srcpath)
    if type(srcpathes) == "string" then
        return os._cp(srcpathes, dstpath, rootdir, opt)
    else
        for _, _srcpath in ipairs(srcpathes) do
            local ok, errors = os._cp(_srcpath, dstpath, rootdir, opt)
            if not ok then
                return false, errors
            end
        end
    end
    return true
end

-- move files or directories
function os.mv(srcpath, dstpath, opt)

    -- check arguments
    if not srcpath or not dstpath then
        return false, string.format("invalid arguments!")
    end

    -- copy files or directories
    srcpath = tostring(srcpath)
    dstpath = tostring(dstpath)
    local srcpathes = os._match_wildcard_pathes(srcpath)
    if type(srcpathes) == "string" then
        return os._mv(srcpathes, dstpath, opt)
    else
        for _, _srcpath in ipairs(srcpathes) do
            local ok, errors = os._mv(_srcpath, dstpath, opt)
            if not ok then
                return false, errors
            end
        end
    end
    return true
end

-- remove files or directories
function os.rm(filepath, opt)
    opt = opt or {}

    -- check arguments
    if not filepath then
        return false, string.format("invalid arguments!")
    end

    -- do it in the asynchronous task
    if opt.async and xmake.in_main_thread() then
       return os._async_task().rm(filepath, {detach = opt.detach})
    end

    -- remove file or directories
    filepath = tostring(filepath)
    local filepathes = os._match_wildcard_pathes(filepath)
    if type(filepathes) == "string" then
        local ok, errors = os._rm(filepathes)
        if not ok then
            return false, errors
        end
        if opt.emptydirs then
            return os._rm_empty_parentdirs(filepathes)
        end
    else
        for _, _filepath in ipairs(filepathes) do
            local ok, errors = os._rm(_filepath)
            if not ok then
                return false, errors
            end
            if opt.emptydirs then
                ok, errors = os._rm_empty_parentdirs(_filepath)
                if not ok then
                    return false, errors
                end
            end
        end
    end
    return true
end

-- link file or directory to the new symfile
function os.ln(srcpath, dstpath, opt)
    opt = opt or {}
    srcpath = tostring(srcpath)
    dstpath = tostring(dstpath)
    if opt.force and os.isfile(dstpath) then
        os.rmfile(dstpath)
    end
    if not os.link(srcpath, dstpath) then
        return false, string.format("cannot link %s to %s, %s", srcpath, dstpath, os.strerror())
    end
    return true
end

-- change to directory
function os.cd(dir)
    assert(dir)

    -- we can only change directory in main thread
    if not xmake.in_main_thread() then
        local thread = require("base/thread")
        os.raise("we cannot change directory in non-main thread(%s)", thread.running() or "unknown")
    end

    -- support path instance
    dir = tostring(dir)

    -- change to the previous directory?
    local oldir = os.curdir()
    if dir == "-" then
        if os._PREDIR then
            dir = os._PREDIR
            os._PREDIR = nil
        else
            return nil, string.format("not found the previous directory %s", os.strerror())
        end
    end

    -- no changed?
    if dir == oldir then
        return oldir
    end

    -- do change directory
    if os.isdir(dir) then
        if not os.chdir(dir) then
            return nil, string.format("cannot change directory %s %s", dir, os.strerror())
        end
        os._PREDIR = oldir
    else
        return nil, string.format("cannot change directory %s, not found this directory %s", dir, os.strerror())
    end

    os._notify_curdir_changed()
    return oldir
end

-- touch file or directory, it will modify atime/mtime or create a new file
-- we will do not change it if atime/mtime is zero
function os.touch(filepath, opt)
    opt = opt or {}
    if os._touch and not os._touch(filepath, opt.atime or 0, opt.mtime or 0) then
        return false, string.format("cannot touch %s, %s", filepath, os.strerror())
    end
    return true
end

-- create directories
function os.mkdir(dir)

    -- check arguments
    if not dir then
        return false, string.format("invalid arguments!")
    end

    -- support path instance
    dir = tostring(dir)

    -- create directories
    local dirs = table.wrap(os._match_wildcard_pathes(dir))
    for _, _dir in ipairs(dirs) do
        if not os._mkdir(_dir) then
            return false, string.format("cannot create directory: %s, %s", _dir, os.strerror())
        end
    end
    return true
end

-- remove directories
function os.rmdir(dir, opt)

    -- check arguments
    if not dir then
        return false, string.format("invalid arguments!")
    end

    -- do it in the asynchronous task
    if opt and opt.async and xmake.in_main_thread() then
        return os._async_task().rmdir(dir, {detach = opt.detach})
    end

    -- support path instance
    dir = tostring(dir)

    -- remove directories
    local dirs = table.wrap(os._match_wildcard_pathes(dir))
    for _, _dir in ipairs(dirs) do
        if not os._rmdir(_dir) then
            return false, string.format("cannot remove directory: %s, %s", _dir, os.strerror())
        end
    end
    return true
end

-- get the current directory
function os.curdir()
    local curdir = os._CURDIR
    if curdir == nil then
        curdir = os._curdir()
        os._CURDIR = curdir
    end
    return curdir
end

-- get the temporary directory
function os.tmpdir(opt)

    -- is in fakeroot? @note: uid always be 0 in root and fakeroot
    if os._FAKEROOT == nil then
        local ldpath = os.getenv("LD_LIBRARY_PATH")
        if ldpath and ldpath:find("libfakeroot", 1, true) then
            os._FAKEROOT = true
        else
            os._FAKEROOT = false
        end
    end

    -- get root tmpdir
    local tmpdir_root = nil
    if opt and opt.ramdisk == false then
        if os._ROOT_TMPDIR == nil then
            os._ROOT_TMPDIR = (os.getenv("XMAKE_TMPDIR") or os.getenv("TMPDIR") or os._tmpdir()):trim()
        end
        tmpdir_root = os._ROOT_TMPDIR
    else
        if os._ROOT_TMPDIR_RAM == nil then
            os._ROOT_TMPDIR_RAM = (os.getenv("XMAKE_TMPDIR") or os._ramdir() or os.getenv("TMPDIR") or os._tmpdir()):trim()
        end
        tmpdir_root = os._ROOT_TMPDIR_RAM
    end

    -- make sub-directory name
    local subdir = os._TMPSUBDIR
    if not subdir then
        local name = "." .. xmake._NAME
        subdir = path.join((os._FAKEROOT and (name .. "fake") or name) .. (os.uid().euid or ""), os.date("%y%m%d"))
        os._TMPSUBDIR = subdir
    end

    -- get a temporary directory for each user
    local tmpdir = path.join(tmpdir_root, subdir)
    if not os.isdir(tmpdir) then
        os.mkdir(tmpdir)
    end
    return tmpdir
end

-- generate the temporary file path
--
-- e.g.
-- os.tmpfile("key")
-- os.tmpfile({key = "xxx", ramdisk = false})
--
function os.tmpfile(opt_or_key)
    local opt
    local key = opt_or_key
    if type(key) == "table" then
        key = opt_or_key.key
        opt = opt_or_key
    end
    local filename = "_" .. (key and hash.strhash128(key) or (hash.rand128()))
    return path.join(os.tmpdir(opt), filename)
end

-- exit program
function os.exit(...)
    return os._exit(...)
end

-- register exit callback
--
-- e.g.
-- os.atexit(function (ok, errors)
--     print(ok, errors)
-- end)
--
function os.atexit(on_exit)
    local exit_callbacks = os._EXIT_CALLBACKS
    if exit_callbacks == nil then
        exit_callbacks = {}
        os._EXIT_CALLBACKS = exit_callbacks
    end
    table.insert(exit_callbacks, on_exit)
end

-- run command
function os.run(cmd)

    -- parse arguments
    local argv = os.argv(cmd)
    if not argv or #argv <= 0 then
        return false, string.format("invalid command: %s", cmd)
    end

    -- run it
    return os.runv(argv[1], table.slice(argv, 2))
end

-- run command with arguments list
function os.runv(program, argv, opt)

    -- init options
    opt = opt or {}

    -- make temporary log file
    local logfile = os.tmpfile()

    -- execute it
    local ok, errors = os.execv(program, argv, table.join(opt, {stdout = opt.stdout or logfile, stderr = opt.stderr or logfile}))
    if ok ~= 0 then

        -- get command
        local cmd = program
        if argv then
            cmd = cmd .. " " .. os.args(argv)
        end

        -- get subprocess errors
        if ok ~= nil then
            errors = io.readfile(logfile)
            if not errors or #errors == 0 then
                errors = string.format("runv(%s) failed(%d)", cmd, ok)
            end
        else
            errors = string.format("cannot runv(%s), %s", cmd, errors and errors or "unknown reason")
        end

        os.rm(logfile)
        return false, errors
    end
    os.rm(logfile)
    return true
end

-- execute command
function os.exec(cmd)

    -- parse arguments
    local argv = os.argv(cmd)
    if not argv or #argv <= 0 then
        return -1
    end

    -- run it
    return os.execv(argv[1], table.slice(argv, 2))
end

-- execute command with arguments list
--
-- @param program     "clang", "xcrun -sdk macosx clang", "~/dir/test\ xxx/clang"
--        filename    "clang", "xcrun"", "~/dir/test\ xxx/clang"
-- @param argv        the arguments
-- @param opt         the options, e.g. {stdin = filepath/file/pipe, stdout = filepath/file/pipe, stderr = filepath/file/pipe,
--                                       envs = {PATH = "xxx;xx", CFLAGS = "xx"}}
--
function os.execv(program, argv, opt)

    -- is not executable program file?
    opt = opt or {}
    local filename = tostring(program)
    if not os.isexec(program) then

        -- parse the filename and arguments, e.g. "xcrun -sdk macosx clang"
        local splitinfo = program:split("%s")
        filename = splitinfo[1]
        if #splitinfo > 1 then
            argv = table.join(table.slice(splitinfo, 2), argv)
        end
    end

    -- run shell file? parse `#!/usr/bin/env bash` in xx.sh
    --
    -- e.g. os.execv("./configure", {"--help"}) => os.execv("/usr/bin/env", {"bash", "./configure", "--help"})
    if opt.shell and os.isfile(filename) then
        local shellfile = filename
        local file = io.open(filename, 'r')
        for line in file:lines() do
            if line and line:startswith("#!") then
                -- we cannot run `/bin/sh` directly on windows
                -- because `/bin/sh` is not real file path, maybe we need to convert it.
                local host = os.host()
                if host == "windows" then
                    filename = os._get_shell_path(opt) or "sh"
                    argv = table.join(shellfile, argv)
                else
                    line = line:sub(3)
                    local shellargv = {}
                    local splitinfo = line:split("%s")
                    filename = splitinfo[1]
                    if #splitinfo > 1 then
                        shellargv = table.slice(splitinfo, 2)
                    end
                    table.insert(shellargv, shellfile)
                    table.join2(shellargv, argv)
                    argv = shellargv
                end
                break
            end
        end
        file:close()
    end

    -- uses the given environments?
    local envs = nil
    local setenvs = opt.setenvs or opt.envs
    local addenvs = opt.addenvs
    if setenvs or addenvs then
        local envars = os.getenvs()
        if setenvs then
            for k, v in pairs(setenvs) do
                if type(v) == "table" then
                    v = path.joinenv(v)
                end
                envars[k] = v
            end
        end
        if addenvs then
            for k, v in pairs(addenvs) do
                if type(v) == "table" then
                    v = path.joinenv(v)
                end
                local o = envars[k]
                if o then
                    v = v .. path.envsep() .. o
                end
                envars[k] = v
            end
        end
        envs = {}
        for k, v in pairs(envars) do
            -- we try to fix too long value before running process
            if type(v) == "string" and #v > 4096 and os.host() == "windows" then
                v = os._deduplicate_pathenv(v)
            end
            table.insert(envs, k .. '=' .. v)
        end
    end

    -- init open options
    local openopt = {
        envs = envs,
        stdin = opt.stdin,
        stdout = opt.stdout,
        stderr = opt.stderr,
        curdir = opt.curdir,
        detach = opt.detach,
        exclusive = opt.exclusive}

    -- profile process performance
    local runtime
    local profileperf = os._is_profiling_process_perf()
    if profileperf then
        runtime = os.mclock()
    end

    -- open command
    local ok = -1
    local errors
    local proc = process.openv(filename, argv or {}, openopt)
    if proc ~= nil then

        -- trace process
        if os._is_tracing_process() then
            -- we cannot use cprint, it will cause dead-loop on windows, winos.version/os.iorunv
            utils.print("%s: %s %s", proc, filename, argv and os.args(argv) or "")
        end

        -- wait process
        if not opt.detach then
            local waitok, status = proc:wait(opt.timeout or -1)
            if waitok > 0 then
                ok = status
            elseif waitok == 0 and opt.timeout then
                proc:kill()
                waitok, status = proc:wait(-1)
                if waitok > 0 then
                    ok = status
                end
                errors = "wait process timeout"
            end
        else
            ok = 0
        end

        -- close process
        proc:close()

        -- save profile info
        if profileperf then
            runtime = os.mclock() - runtime

            local profileinfo = os._PROCESS_PROFILEINFO
            if profileinfo == nil then
                profileinfo = {}
                os._PROCESS_PROFILEINFO = profileinfo
            end

            local runcmd
            runcmd = filename
            if argv and #argv > 0 then
                runcmd = runcmd .. " " .. os.args(argv)
            end
            local perfinfo = profileinfo[runcmd]
            if perfinfo == nil then
                perfinfo = {}
                profileinfo[runcmd] = perfinfo
            end
            perfinfo.totaltime = (perfinfo.totaltime or 0) + runtime
            perfinfo.runcount = (perfinfo.runcount or 0) + 1
        end
    else
        -- cannot execute process
        return nil, os.strerror()
    end
    return ok, errors
end

-- run command and return output and error data
function os.iorun(cmd)

    -- parse arguments
    local argv = os.argv(cmd)
    if not argv or #argv <= 0 then
        return false, string.format("invalid command: %s", cmd)
    end

    -- run it
    return os.iorunv(argv[1], table.slice(argv, 2))
end

-- run command with arguments and return output and error data
function os.iorunv(program, argv, opt)

    -- make temporary output and error file
    opt = opt or {}
    local outfile = os.tmpfile()
    local errfile = os.tmpfile()

    -- run command
    local ok, errors = os.execv(program, argv, table.join(opt, {stdout = outfile, stderr = errfile}))
    if ok == nil then
        local cmd = program
        if argv then
            cmd = cmd .. " " .. os.args(argv)
        end
        errors = string.format("cannot runv(%s), %s", cmd, errors and errors or "unknown reason")
    end

    -- get output and error data
    local outdata = io.readfile(outfile)
    local errdata = io.readfile(errfile)

    -- remove the temporary output and error file
    os.rm(outfile)
    os.rm(errfile)
    return ok == 0, outdata, errdata, errors
end

-- raise an exception and abort the current script
--
-- the parent function will capture it if we uses pcall or xpcall
--
function os.raiselevel(level, msg, ...)

    -- set level of this function
    level = level + 1

    -- flush log
    log:flush()

    -- flush io buffer
    io.flush()

    -- raise it
    if type(msg) == "string" then
        error(string.tryformat(msg, ...), level)
    elseif type(msg) == "table" then
        local errobjstr, errors = string.serialize(msg, {strip = true, indent = false})
        if errobjstr then
            error("[@encode(error)]: " .. errobjstr, level)
        else
            error(errors, level)
        end
    elseif msg ~= nil then
        error(tostring(msg), level)
    else
        error(msg, level)
    end
end

-- raise an exception and abort the current script
--
-- the parent function will capture it if we uses pcall or xpcall
--
function os.raise(msg, ...)
    -- add return to make it a tail call
    return os.raiselevel(1, msg, ...)
end

-- is executable program file?
function os.isexec(filepath)
    if os.host() == "windows" then
        local exts_map = os._ISEXEC_WINDOWS_EXTS_MAP
        if not exts_map then
            local exts = {".exe", ".com", ".cmd", ".bat", ".ps1", ".sh"}
            exts_map = {}
            for _, ext in ipairs(exts) do
                exts_map[ext] = true
            end
            os._ISEXEC_WINDOWS_EXTS_MAP = exts_map
        end
        if os.isfile(filepath) then
            local extension = path.extension(filepath)
            if extension and #extension > 0 then
                if exts_map[extension:lower()] then
                    return true
                end
            else
                -- detect executable file header
                --
                -- @note only for files without extension, because .dll is also PE
                -- pe: native windows executables
                -- ape: cosmocc/APE executables (e.g. `cosmocc -o foo.exe ...`)
                -- shebang: scripts starting with `#!`
                local format = nil
                if binutils and binutils.format then
                    format = binutils.format(filepath)
                end
                if format == "pe" or format == "ape" or format == "shebang" then
                    return true
                end
            end
        end
        for suffix, _ in pairs(exts_map) do
            if os.isfile(filepath .. suffix) then
                return true
            end
        end
    elseif os.isfile(filepath) then
        if os._access then
            return os._access(filepath, "x")
        else
            return true
        end
    end
    return false
end

-- get system host
function os.host()
    return xmake._HOST
end

-- get system architecture
function os.arch()
    return xmake._ARCH
end

-- get subsystem host, e.g. msys, cygwin on windows
function os.subhost()
    return xmake._SUBHOST
end

-- get subsystem host architecture
function os.subarch()
    return xmake._SUBARCH
end

-- get features
function os.features()
    return xmake._FEATURES
end

-- the current host is belong to the given hosts?
function os.is_host(...)
    return os._is_host(os.host(), ...)
end

-- the current architecture is belong to the given architectures?
function os.is_arch(...)
    return os._is_arch(os.arch(), ...)
end

-- the current subsystem host is belong to the given hosts?
function os.is_subhost(...)
    return os._is_host(os.subhost(), ...)
end

-- the current subsystem architecture is belong to the given architectures?
function os.is_subarch(...)
    return os._is_arch(os.subarch(), ...)
end

-- get the system null device
function os.nuldev(input)

    if input then
        if os.host() == "windows" then
            -- init the input nuldev
            if xmake._NULDEV_INPUT == nil then
                -- create an empty file
                --
                -- for fix issue on mingw:
                -- $ gcc -fopenmp -S -o nul -xc nul
                -- gcc: fatal error：input file 'nul' is the same as output file
                --
                local inputfile = os.tmpfile()
                io.writefile(inputfile, "")
                xmake._NULDEV_INPUT = inputfile
            end
        else
            if xmake._NULDEV_INPUT == nil then
                xmake._NULDEV_INPUT = "/dev/null"
            end
        end
        return xmake._NULDEV_INPUT
    else
        if os.host() == "windows" then
            -- @note cannot cache this file path to avoid multi-processes writing to the same file at the same time
            return os.tmpfile()
        else
            if xmake._NULDEV_OUTPUT == nil then
                xmake._NULDEV_OUTPUT = "/dev/null"
            end
            return xmake._NULDEV_OUTPUT
        end
    end
end

-- get uid
function os.uid(...)
    os._UID = {}
    if os._uid then
        os._UID = os._uid(...) or {}
    end
    return os._UID
end

-- get gid
function os.gid(...)
    os._GID = {}
    if os._gid then
        os._GID = os._gid(...) or {}
    end
    return os._GID
end

-- get pid
function os.getpid(...)
    local pid = os._PID
    if pid == nil then
        pid = os._getpid()
        os._PID = pid
    end
    return pid
end

-- check the current command is running as root
function os.isroot()
    return os.uid().euid == 0
end

-- is case-insensitive filesystem?
function os.fscase(filepath)
    if os._FSCASE == nil or filepath then
        if os._fscase then
            if filepath then
                assert(os.exists(filepath), filepath .. " not found in os.fscase()")
            else
                local tmpdir = os.tmpdir()
                if not os.isdir(tmpdir) then
                    os.mkdir(tmpdir)
                end
                filepath = tmpdir
            end
            local fscase = os._fscase(filepath)
            if fscase ~= -1 then
                os._FSCASE = (fscase == 1)
                return os._FSCASE
            end
        end
        if os.host() == "windows" then
            os._FSCASE = false
        else

            -- get temporary directory
            local tmpdir = os.tmpdir()

            -- get matching pattern, this is equal to os.filedirs(path.join(tmpdir, "*"))
            --
            -- @note we cannot use os.match() becase os.fscase() will be called in os.match()
            --
            local pattern = path.join(tmpdir, "*")
            pattern = pattern:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
            pattern = pattern:gsub("%*", "\002")
            pattern = pattern:gsub("\002", "[^/]*")

            -- attempt to detect it
            local file = os.find(tmpdir, pattern, 0, -1, nil, function (file, isdir) return false end)
            if file and #file > 0 then
                local file1 = file[1]
                local file2 = file1:gsub(".",  function (ch) return (ch >= 'a' and ch <= 'z') and ch:upper() or ch:lower() end)
                os._FSCASE = not (os.exists(file1) and os.exists(file2))
            else
                os._FSCASE = true
            end
        end
    end
    return os._FSCASE
end

-- get shell
function os.shell()
    return require("base/tty").shell()
end

-- get term
function os.term()
    return require("base/tty").term()
end

-- get all current environments variables
function os.getenvs()
    local envs = os._getenvs()
    if envs then
        -- we need to be compatible with the old binary core, if it's array (<= v3.0.3)
        if envs[1] ~= nil then
            local result = {}
            for _, line in ipairs(envs) do
                local p = line:find('=', 1, true)
                if p then
                    local key = line:sub(1, p - 1):trim()
                    -- only translate Path to PATH on windows
                    -- @see https://github.com/xmake-io/xmake/issues/3752
                    if os.host() == "windows" and key:lower() == "path" then
                        key = key:upper()
                    end
                    local values = line:sub(p + 1):trim()
                    if #key > 0 then
                        result[key] = values
                    end
                end
            end
            envs = result
        end
    end
    return envs
end

-- set all current environment variables
-- e.g. envs["PATH"] = "/xxx:/yyy/foo"
function os.setenvs(envs)
    local oldenvs = os.getenvs()
    if envs then
        local changed = false
        -- remove new added values
        for name, _ in pairs(oldenvs) do
            if not envs[name] then
                if os._setenv(name, "") then
                    changed = true
                end
            end
        end
        -- change values
        for name, values in pairs(envs) do
            if oldenvs[name] ~= values then
                if os._setenv(name, values) then
                    changed = true
                end
            end
        end
        if changed then
            os._notify_envs_changed(envs)
        end
    end
    return oldenvs
end

-- add environment variables
-- e.g. envs["PATH"] = "/xxx:/yyy/foo"
function os.addenvs(envs)
    local oldenvs = os.getenvs()
    if envs then
        local changed = false
        for name, values in pairs(envs) do
            local ok
            local oldenv = oldenvs[name]
            if oldenv == "" or oldenv == nil then
                ok = os._setenv(name, values)
            elseif not oldenv:startswith(values) then
                ok = os._setenv(name, values .. path.envsep() .. oldenv)
            end
            if ok then
                changed = true
            end
        end
        if changed then
            os._notify_envs_changed()
        end
    end
    return oldenvs
end

-- join environment variables
function os.joinenvs(envs, oldenvs)
    oldenvs = oldenvs or os.getenvs()
    local newenvs = oldenvs
    if envs then
        newenvs = table.copy(oldenvs)
        for name, values in pairs(envs) do
            local oldenv = oldenvs[name]
            if oldenv == "" or oldenv == nil then
                newenvs[name] = values
            elseif not oldenv:startswith(values) then
                newenvs[name] = values .. path.envsep() .. oldenv
            end
        end
    end
    return newenvs
end

-- set values to environment variable
function os.setenv(name, ...)
    local ok
    local values = {...}
    if #values <= 1 then
        -- keep compatible with original implementation
        ok = os._setenv(name, values[1] or "")
    else
        ok = os._setenv(name, path.joinenv(values))
    end
    if ok then
        os._notify_envs_changed()
    end
    return ok
end

-- add values to environment variable
function os.addenv(name, ...)
    local values = {...}
    if #values > 0 then
        local ok
        local changed = false
        local oldenv = os.getenv(name)
        local appendenv = path.joinenv(values)
        if oldenv == "" or oldenv == nil then
            ok = os._setenv(name, appendenv)
            if ok then
                changed = true
            end
        elseif not oldenv:startswith(appendenv) then
            ok = os._setenv(name, appendenv .. path.envsep() .. oldenv)
            if ok then
                changed = true
            end
        else
            ok = true
        end
        if changed then
            os._notify_envs_changed()
        end
        return ok
    else
        return true
    end
end

-- set values to environment variable with the given seperator
function os.setenvp(name, values, sep)
    sep = sep or path.envsep()
    local ok = os._setenv(name, table.concat(table.wrap(values), sep))
    if ok then
        os._notify_envs_changed()
    end
    return ok
end

-- add values to environment variable with the given seperator
function os.addenvp(name, values, sep)
    sep = sep or path.envsep()
    values = table.wrap(values)
    if #values > 0 then
        local ok
        local changed = false
        local oldenv = os.getenv(name)
        local appendenv = table.concat(values, sep)
        if oldenv == "" or oldenv == nil then
            ok = os._setenv(name, appendenv)
            if ok then
                changed = true
            end
        elseif not oldenv:startswith(appendenv) then
            ok = os._setenv(name, appendenv .. sep .. oldenv)
            if ok then
                changed = true
            end
        else
            ok = true
        end
        if changed then
            os._notify_envs_changed()
        end
        return ok
    else
        return true
    end
end

-- read string data from pasteboard
function os.pbpaste()
    if os.host() == "macosx" then
        local ok, result = os.iorun("pbpaste")
        if ok then
            return result
        end
    elseif os.host() == "linux" then
        local ok, result = os.iorun("xsel --clipboard --output")
        if ok then
            return result
        end
    else
        -- TODO
    end
end

-- copy string data to pasteboard
function os.pbcopy(data)
    if os.host() == "macosx" then
        os.run("bash -c \"echo '" .. data .. "' | pbcopy\"")
    elseif os.host() == "linux" then
        os.run("bash -c \"echo '" .. data .. "' | xsel --clipboard --input\"")
    else
        -- TODO
    end
end

-- get cpu info
function os.cpuinfo(name)
    return require("base/cpu").info(name)
end

-- get memory info
function os.meminfo(name)
    return require("base/memory").info(name)
end

-- get the default parallel jobs number
function os.default_njob()
    local njob
    local ncpu = os.cpuinfo().ncpu
    if ncpu > 2 then
        njob = ncpu + 2
        if os.host() == "windows" and njob > 128 then
            njob = 128
        end
        if njob > 512 then
            njob = 512
        end
    elseif ncpu == 2 then
        njob = 3
    else
        njob = 2
    end
    return njob or 2
end

-- read the content of symlink
function os.readlink(symlink)
    return os._readlink(path.absolute(symlink))
end

-- get the program directory
function os.programdir()
    return xmake._PROGRAM_DIR
end

-- get the program file
function os.programfile()
    return xmake._PROGRAM_FILE
end

-- get the working directory
function os.workingdir()
    return xmake._WORKING_DIR
end

-- get the project directory
function os.projectdir()
    return xmake._PROJECT_DIR
end

-- get the project file
function os.projectfile()
    return xmake._PROJECT_FILE
end

-- return module
return os
