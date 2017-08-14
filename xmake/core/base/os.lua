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

-- define module
local os = os or {}

-- load modules
local io        = require("base/io")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")

-- save original interfaces
os._uid         = os._uid or os.uid
os._gid         = os._gid or os.gid
os._mkdir       = os._mkdir or os.mkdir
os._rmdir       = os._rmdir or os.rmdir
os._tmpdir      = os._tmpdir or os.tmpdir
os._setenv      = os._setenv or os.setenv
os._versioninfo = os._versioninfo or os.versioninfo

-- copy single file or directory 
function os._cp(src, dst)
    
    -- check
    assert(src and dst)

    -- is file?
    if os.isfile(src) then
        
        -- the destination is directory? append the filename
        if os.isdir(dst) or dst:endswith(path.seperator()) then
            dst = path.join(dst, path.filename(src))
        end

        -- copy file
        if not os.cpfile(src, dst) then
            return false, string.format("cannot copy file %s to %s %s", src, dst, os.strerror())
        end
    -- is directory?
    elseif os.isdir(src) then
        
        -- the destination directory exists? append the filename
        if os.isdir(dst) or dst:endswith(path.seperator()) then
            dst = path.join(dst, path.filename(path.translate(src)))
        end

        -- copy directory
        if not os.cpdir(src, dst) then
            return false, string.format("cannot copy directory %s to %s %s", src, dst, os.strerror())
        end

    -- not exists?
    else
        return false, string.format("cannot copy file %s, not found this file %s", src, os.strerror())
    end
    
    -- ok
    return true
end

-- move single file or directory
function os._mv(src, dst)
    
    -- check
    assert(src and dst)

    -- exists file or directory?
    if os.exists(src) then
 
        -- the destination directory exists? append the filename
        if os.isdir(dst) or dst:endswith(path.seperator()) then
            dst = path.join(dst, path.filename(path.translate(src)))
        end

        -- move file or directory
        if not os.rename(src, dst) then
            return false, string.format("cannot move %s to %s %s", src, dst, os.strerror())
        end
    -- not exists?
    else
        return false, string.format("cannot move %s to %s, not found this file %s", src, dst, os.strerror())
    end
    
    -- ok
    return true
end

-- remove single file or directory 
function os._rm(filedir)
    
    -- check
    assert(filedir)

    -- is file?
    if os.isfile(filedir) then
        -- remove file
        if not os.rmfile(filedir) then
            return false, string.format("cannot remove file %s %s", filedir, os.strerror())
        end
    -- is directory?
    elseif os.isdir(filedir) then
        -- remove directory
        if not os.rmdir(filedir) then
            return false, string.format("cannot remove directory %s %s", filedir, os.strerror())
        end
    end

    -- ok
    return true
end

-- translate arguments for wildcard
function os.argw(argv)

    -- match all arguments
    local results = {}
    for _, arg in ipairs(table.wrap(argv)) do
        
        -- exists wildcards?
        if arg:find("([%+%-%^%$%*%[%]%%])") then
            local pathes = os.match(arg, 'a')
            if #pathes > 0 then
                table.join2(results, pathes)
            else
                table.insert(results, arg)
            end
        else
            table.insert(results, arg)
        end
    end

    -- ok?
    return results
end

-- make string from arguments list
function os.args(argv)

    -- make it
    local args = nil
    for _, arg in ipairs(table.wrap(argv)) do
        arg = arg:trim()
        if #arg > 0 then
            arg = arg:gsub("([\"\\])", "\\%1")
            if arg:find("%s") then
                if args then
                    args = args .. " \"" .. arg .. "\""
                else
                    args = "\"" .. arg .. "\""
                end
            else
                if args then
                    args = args .. " " .. arg
                else
                    args = arg
                end
            end
        end
    end

    -- ok?
    return args or ""
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
-- local file = os.match("./src/test.c")
-- @endcode
--
function os.match(pattern, mode)

    -- get the excludes
    local excludes = pattern:match("|.*$")
    if excludes then excludes = excludes:split("|") end

    -- translate excludes
    if excludes then
        local _excludes = {}
        for _, exclude in ipairs(excludes) do
            exclude = path.translate(exclude)
            exclude = exclude:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
            exclude = exclude:gsub("%*%*", "\001")
            exclude = exclude:gsub("%*", "\002")
            exclude = exclude:gsub("\001", ".*")
            exclude = exclude:gsub("\002", "[^/]*")
            table.insert(_excludes, exclude)
        end
        excludes = _excludes
    end

    -- translate path and remove some repeat separators
    pattern = path.translate(pattern:gsub("|.*$", ""))

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
    local starpos = pattern:find("%*")
    if starpos then
        rootdir = rootdir:sub(1, starpos - 1)
    end
    rootdir = path.directory(rootdir)

    -- is recurse?
    local recurse = pattern:find("**", nil, true)

    -- convert pattern to a lua pattern
    pattern = pattern:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
    pattern = pattern:gsub("%*%*", "\001")
    pattern = pattern:gsub("%*", "\002")
    pattern = pattern:gsub("\001", ".*")
    pattern = pattern:gsub("\002", "[^/]*")

    -- find it
    return os.find(rootdir, pattern, recurse, mode, excludes)
end

-- match directories
function os.dirs(pattern, ...)
    return os.match(pattern, 'd')
end

-- match files
function os.files(pattern)
    return os.match(pattern, 'f')
end

-- match files and directories
function os.filedirs(pattern)
    return os.match(pattern, 'a')
end

-- copy files or directories
function os.cp(...)
   
    -- check arguments
    local args = {...}
    if #args < 2 then
        return false, string.format("invalid arguments: %s", table.concat(args, ' '))
    end

    -- get source pathes
    local srcpathes = table.slice(args, 1, #args - 1)

    -- get destinate path
    local dstpath = args[#args]

    -- copy files or directories
    for _, srcpath in ipairs(os.argw(srcpathes)) do
        local ok, errors = os._cp(srcpath, dstpath)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- move files or directories
function os.mv(...)
   
    -- check arguments
    local args = {...}
    if #args < 2 then
        return false, string.format("invalid arguments: %s", table.concat(args, ' '))
    end

    -- get source pathes
    local srcpathes = table.slice(args, 1, #args - 1)

    -- get destinate path
    local dstpath = args[#args]

    -- copy files or directories
    for _, srcpath in ipairs(os.argw(srcpathes)) do
        local ok, errors = os._mv(srcpath, dstpath)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- remove files or directories
function os.rm(...)
    
    -- check arguments
    local args = {...}
    if #args < 1 then
        return false, string.format("invalid arguments: %s", table.concat(args, ' '))
    end

    -- create directories
    for _, filedir in ipairs(os.argw(args)) do
        if not os._rm(filedir) then
            return false, string.format("remove: %s failed!", filedir)
        end
    end

    -- ok
    return true
end

-- change to directory
function os.cd(dir)

    -- check
    assert(dir)

    -- the previous directory
    local oldir = os.curdir()

    -- change to the previous directory?
    if dir == "-" then
        -- exists the previous directory?
        if os._PREDIR then
            dir = os._PREDIR
            os._PREDIR = nil
        else
            -- error
            return nil, string.format("not found the previous directory %s", os.strerror())
        end
    end

    -- is directory?
    if os.isdir(dir) then

        -- change to directory
        if not os.chdir(dir) then
            return nil, string.format("cannot change directory %s %s", dir, os.strerror())
        end

        -- save the previous directory
        os._PREDIR = oldir

    -- not exists?
    else
        return nil, string.format("cannot change directory %s, not found this directory %s", dir, os.strerror())
    end
    
    -- ok
    return oldir
end

-- create directories
function os.mkdir(...)
   
    -- check arguments
    local args = {...}
    if #args < 1 then
        return false, string.format("invalid arguments: %s", table.concat(args, ' '))
    end

    -- create directories
    for _, dir in ipairs(os.argw(args)) do
        if not os._mkdir(dir) then
            return false, string.format("create directory: %s failed!", dir)
        end
    end

    -- ok
    return true
end

-- remove directories
function os.rmdir(...)
   
    -- check arguments
    local args = {...}
    if #args < 1 then
        return false, string.format("invalid arguments: %s", table.concat(args, ' '))
    end

    -- create directories
    for _, dir in ipairs(os.argw(args)) do
        if not os._rmdir(dir) then
            return false, string.format("remove directory: %s failed!", dir)
        end
    end

    -- ok
    return true
end

-- get the temporary directory
function os.tmpdir()

    -- get a temporary directory for each user
    local tmpdir = path.join(os._tmpdir(), ".xmake" .. (os.uid().euid or ""))

    -- ensure this directory exist
    if not os.isdir(tmpdir) then
        os.mkdir(tmpdir)
    end
    return tmpdir
end

-- generate the temporary file path
function os.tmpfile()

    -- make it
    return path.join(os.tmpdir(), "_" .. (hash.uuid():gsub("-", "")))
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
function os.runv(program, argv)

    -- make temporary log file
    local log = os.tmpfile()

    -- execute it
    local ok = os.execv(program, argv, log, log)
    if ok ~= 0 then

        -- make errors
        local errors = io.readfile(log)
        if not errors or #errors == 0 then
            if argv ~= nil then
                errors = string.format("runv(%s %s) failed(%d)!", program, table.concat(argv, ' '), ok)
            else
                errors = string.format("runv(%s) failed(%d)!", program, ok)
            end
        end

        -- remove the temporary log file
        os.rm(log)

        -- failed
        return false, errors
    end

    -- remove the temporary log file
    os.rm(log)

    -- ok
    return true
end

-- execute command 
function os.exec(cmd, outfile, errfile)

    -- parse arguments
    local argv = os.argv(cmd)
    if not argv or #argv <= 0 then
        return -1
    end

    -- run it
    return os.execv(argv[1], table.slice(argv, 2), outfile, errfile)
end

-- execute command with arguments list
--
-- program:     "clang", "xcrun -sdk macosx clang", "~/dir/test\ xxx/clang"
-- filename:    "clang", "xcrun"", "~/dir/test\ xxx/clang"
--
function os.execv(program, argv, outfile, errfile)

    -- init arguments
    local args = os.argw(argv)

    -- is not executable program file?
    local filename = program
    if not os.isexec(program) then

        -- parse the filename and arguments, .e.g "xcrun -sdk macosx clang"
        local splitinfo = program:split("%s")
        filename = splitinfo[1]
        if #splitinfo > 1 then
            args = table.join(table.slice(splitinfo, 2), args)
        end
    end

    -- open command
    local ok = -1
    local proc = process.openv(filename, args, outfile, errfile)
    if proc ~= nil then

        -- wait process
        local waitok = -1
        local status = -1 
        if coroutine.running() then

            -- save the current directory
            local curdir = os.curdir()

            -- wait it
            repeat
                -- poll it
                waitok, status = process.wait(proc, 0)
                if waitok == 0 then
                    waitok, status = coroutine.yield(proc)
                end
            until waitok ~= 0

            -- resume the current directory
            os.cd(curdir)
        else
            waitok, status = process.wait(proc, -1)
        end

        -- get status
        if waitok > 0 then
            ok = status
        end

        -- close process
        process.close(proc)
    end

    -- ok?
    return ok
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
function os.iorunv(program, argv)

    -- make temporary output and error file
    local outfile = os.tmpfile()
    local errfile = os.tmpfile()

    -- run command
    local ok = os.execv(program, argv, outfile, errfile) 

    -- get output and error data
    local outdata = io.readfile(outfile)
    local errdata = io.readfile(errfile)

    -- remove the temporary output and error file
    os.rm(outfile)
    os.rm(errfile)

    -- ok?
    return ok == 0, outdata, errdata
end

-- raise an exception and abort the current script
--
-- the parent function will capture it if we uses pcall or xpcall
--
function os.raise(msg, ...)

    -- raise it
    if msg then
        error(string.tryformat(msg, ...))
    else
        error()
    end
end

-- is executable program file?
function os.isexec(filepath)

    -- check
    assert(filepath)

    -- TODO
    -- check permission

    -- is *.exe for windows?
    if os.host() == "windows" and not filepath:find("%.exe") then
        filepath = filepath .. ".exe"
    end

    -- file exists?
    return os.isfile(filepath)
end

-- get the system host
function os.host()
    return xmake._HOST
end

-- get the system architecture
function os.arch()
    return xmake._ARCH
end

-- get the system null device
function os.nuldev()
    return xmake._NULDEV
end

-- get uid
function os.uid(...)
    -- get uid
    os._UID = {}
    if os._uid then
        os._UID = os._uid(...) or {}
    end

    -- ok?
    return os._UID
end

-- get gid
function os.gid(...)
    -- get gid
    os._GID = {}
    if os._gid then
        os._GID = os._gid(...) or {}
    end

    -- ok?
    return os._GID
end

-- check the current command is running as root
function os.isroot()

    -- check it
    return os.uid().euid == 0
end

-- set values to environment variable 
function os.setenv(name, ...)

    -- get separator
    local seperator = utils.ifelse(os.host() == "windows", ';', ':')
    
    -- append values
    return os._setenv(name, table.concat({...}, seperator))
end

-- add values to environment variable 
function os.addenv(name, ...)

    -- get separator
    local seperator = utils.ifelse(os.host() == "windows", ';', ':')
    
    -- append values
    return os.setenv(name, table.concat({...}, seperator) .. seperator ..  (os.getenv(name) or ""))
end

-- get the program directory
function os.programdir()
    return xmake._PROGRAM_DIR
end

-- get the program file
function os.programfile()
    return xmake._PROGRAM_FILE
end

-- get the project directory
function os.projectdir()
    return xmake._PROJECT_DIR
end

-- get the project file
function os.projectfile()
    return xmake._PROJECT_FILE
end

-- get version info
function os.versioninfo()

    -- cache it
    os._VERSIONINFO = os._VERSIONINFO or os._versioninfo()
    return os._VERSIONINFO
end

-- return module
return os
