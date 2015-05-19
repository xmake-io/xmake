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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        os.lua
--

-- define module: os
local os = os or {}

-- load modules
local path      = require("base/path")
local utils     = require("base/utils")

-- copy file or directory
function os.cp(src, dst)
    
    -- check
    assert(src and dst)

    -- is file?
    if os.isfile(src) then
        -- copy file
        if not os.cpfile(src, dst) then
            return false, string.format("cannot copy file %s to %s!", src, dst)
        end
    -- is directory?
    elseif os.isdir(src) then
        -- copy directory
        if not os.cpdir(src, dst) then
            return false, string.format("cannot copy directory %s to %s!", src, dst)
        end
    -- not exists?
    else
        return false, string.format("cannot copy file %s, not found this file!", src)
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
            return false, string.format("cannot move %s to %s!", src, dst)
        end
    -- not exists?
    else
        return false, string.format("cannot move %s to %s, not found this file!", src, dst)
    end
    
    -- ok
    return true
end

-- remove file or directory
function os.rm(path)
    
    -- check
    assert(path)

    -- is file?
    if os.isfile(path) then
        -- remove file
        if not os.rmfile(path) then
            return false, string.format("cannot remove file %s!", path)
        end
    -- is directory?
    elseif os.isdir(path) then
        -- remove directory
        if not os.rmdir(path) then
            return false, string.format("cannot remove directory %s!", path)
        end
    -- not exists?
    else
        return false, string.format("cannot remove file %s, not found this file!", path)
    end
    
    -- ok
    return true
end

-- change to directory
function os.cd(path)

    -- check
    assert(path)

    -- change to the previous directory?
    if path == "-" then
        -- exists the previous directory?
        if os._PREDIR then
            path = os._PREDIR
            os._PREDIR = nil
        else
            -- error
            return false, string.format("not found the previous directory!")
        end
    end
    
    -- is directory?
    if os.isdir(path) then

        -- get the current directory
        local current = os.curdir()

        -- change to directory
        if not os.chdir(path) then
            return false, string.format("cannot change directory %s!", path)
        end

        -- save the previous directory
        os._PREDIR = current

    -- not exists?
    else
        return false, string.format("cannot change directory %s, not found this directory!", path)
    end
    
    -- ok
    return true
end

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
-- @endcode
--
function os.match(pattern, findir)

    -- translate path and remove some repeat separators
    pattern = path.translate(pattern)

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
    return os.find(rootdir, pattern, recurse, findir)
end

-- return module: os
return os
