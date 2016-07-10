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

-- define module
local os = os or {}

-- load modules
local io        = require("base/io")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")

-- match files or directories
--
-- @param pattern   the search pattern 
--                  uses "*" to match any part of a file or directory name,
--                  uses "**" to recurse into subdirectories.
--
-- @param findir    true: find directory, false: find file
-- @return          the result array and count
--
-- @code
-- local dirs, count = os.match("./src/*", true)
-- local files, count = os.match("./src/**.c")
-- local file = os.match("./src/test.c")
-- @endcode
--
function os.match(pattern, findir)

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

    -- patch "./" for matching ok if root directory is '.'
    if rootdir == '.' then
        pattern = "." .. path.seperator() .. pattern
    end
    
    -- find it
    return os.find(rootdir, pattern, recurse, findir, excludes)
end

-- copy file or directory
function os.cp(src, dst)
    
    -- check
    assert(src and dst)

    -- is file?
    if os.isfile(src) then
        
        -- the destination is directory? append the filename
        if os.isdir(dst) then
            dst = path.join(dst, path.filename(src))
        end

        -- copy file
        if not os.cpfile(src, dst) then
            return false, string.format("cannot copy file %s to %s %s", src, dst, os.strerror())
        end
    -- is directory?
    elseif os.isdir(src) then
        
        -- the destination directory exists? append the filename
        if os.isdir(dst) then
            dst = path.join(dst, path.filename(path.translate(src)))
        end

        -- copy directory
        if not os.cpdir(src, dst) then
            return false, string.format("cannot copy directory %s to %s %s", src, dst, os.strerror())
        end
    -- cp dir/*?
    elseif src:find("%*") then

        -- get the root directory
        local starpos = src:find("%*")

        -- match all files
        local files = os.match((src:gsub("%*+", "**")))
        if files then
            for _, file in ipairs(files) do
                local dstfile = string.format("%s/%s", dst, file:sub(starpos))
                if not os.cpfile(file, dstfile) then
                    return false, string.format("cannot copy file %s to %s %s", file, dstfile, os.strerror())
                end
            end
        end

    -- not exists?
    else
        return false, string.format("cannot copy file %s, not found this file %s", src, os.strerror())
    end
    
    -- ok
    return true
end

-- move file or directory
function os.mv(src, dst)
    
    -- check
    assert(src and dst)

    -- exists file or directory?
    if os.exists(src) then
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

-- remove file or directory and remove it if the super directory be empty
function os.rm(file_or_dir, rm_superdir_if_empty)
    
    -- check
    assert(file_or_dir)

    -- is file?
    if os.isfile(file_or_dir) then
        -- remove file
        if not os.rmfile(file_or_dir) then
            return false, string.format("cannot remove file %s %s", file_or_dir, os.strerror())
        end
    -- is directory?
    elseif os.isdir(file_or_dir) then
        -- remove directory
        if not os.rmdir(file_or_dir) then
            return false, string.format("cannot remove directory %s %s", file_or_dir, os.strerror())
        end
    end

    -- remove the super directory if be empty
    if rm_superdir_if_empty then
        local superdir = path.directory(file_or_dir)
        if os.isdir(superdir) then
            os.rmdir(superdir, true)
        end
    end

    -- ok
    return true
end

-- change to directory
function os.cd(dir)

    -- check
    assert(dir)

    -- change to the previous directory?
    if dir == "-" then
        -- exists the previous directory?
        if os._PREDIR then
            dir = os._PREDIR
            os._PREDIR = nil
        else
            -- error
            return false, string.format("not found the previous directory %s", os.strerror())
        end
    end
    
    -- is directory?
    if os.isdir(dir) then

        -- get the current directory
        local current = os.curdir()

        -- change to directory
        if not os.chdir(dir) then
            return false, string.format("cannot change directory %s %s", dir, os.strerror())
        end

        -- save the previous directory
        os._PREDIR = current

    -- not exists?
    else
        return false, string.format("cannot change directory %s, not found this directory %s", dir, os.strerror())
    end
    
    -- ok
    return true
end

-- generate the temporary file path
function os.tmpfile()

    -- make it
    return path.join(os.tmpdir(), path.filename(os.tmpname()))
end

-- run shell
function os.run(cmd)

    -- make temporary log file
    local log = os.tmpfile()

    -- execute it
    local ok = os.exec(cmd, log, log)
    if ok ~= 0 then

        -- make errors
        local errors = io.readall(log)

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

-- run shell with arguments list
function os.runv(shellname, argv)

    -- make temporary log file
    local log = os.tmpfile()

    -- execute it
    local ok = os.execv(shellname, table.wrap(argv), log, log)
    if ok ~= 0 then

        -- make errors
        local errors = io.readall(log)

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

-- execute shell 
function os.exec(cmd, outfile, errfile)

    -- open command
    local ok = -1
    local proc = process.open(cmd, outfile, errfile)
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
                    coroutine.yield()
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

-- execute shell with arguments list
function os.execv(shellname, argv, outfile, errfile)

    -- open command
    local ok = -1
    local proc = process.openv(shellname, table.wrap(argv), outfile, errfile)
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
                    coroutine.yield()
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

-- run shell and return output and error data
function os.iorun(cmd)

    -- make temporary output and error file
    local outfile = os.tmpfile()
    local errfile = os.tmpfile()

    -- run command
    local ok = os.exec(cmd, outfile, errfile) 

    -- get output and error data
    local outdata = io.readall(outfile)
    local errdata = io.readall(errfile)

    -- remove the temporary output and error file
    os.rm(outfile)
    os.rm(errfile)

    -- ok?
    return ok == 0, outdata, errdata
end

-- run shell with arguments and return output and error data
function os.iorunv(shellname, argv)

    -- make temporary output and error file
    local outfile = os.tmpfile()
    local errfile = os.tmpfile()

    -- run command
    local ok = os.execv(shellname, argv, outfile, errfile) 

    -- get output and error data
    local outdata = io.readall(outfile)
    local errdata = io.readall(errfile)

    -- remove the temporary output and error file
    os.rm(outfile)
    os.rm(errfile)

    -- ok?
    return ok == 0, outfile, errdata
end

-- raise an exception and abort the current script
--
-- the parent function will capture it if we uses pcall or xpcall
--
function os.raise(msg, ...)

    -- raise it
    if msg then
        error(string.format(msg, ...))
    else
        error()
    end
end

-- is executable program?
function os.isexec(filepath)

    -- check
    assert(filepath)

    -- TODO
    -- check permission

    -- is *.exe for windows?
    if xmake._HOST == "windows" and not filepath:find("%.exe") then
        filepath = filepath .. ".exe"
    end

    -- file exists?
    return os.isfile(filepath)
end

-- return module
return os
