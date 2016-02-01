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

-- load modules
local io    = require("base/io")
local os    = require("base/os")
local utils = require("base/utils")

-- define module
local sandbox_builtin_os = sandbox_builtin_os or {}

-- copy file or directory
function sandbox_builtin_os.cp(src, dst)
    
    -- check
    assert(src and dst)

    -- done
    local ok, errors = os.cp(src, dst)
    if not ok then
        utils.error(errors)
        utils.abort()
    end

end

-- move file or directory
function sandbox_builtin_os.mv(src, dst)
    
    -- check
    assert(src and dst)

    -- done
    local ok, errors = os.mv(src, dst)
    if not ok then
        utils.error(errors)
        utils.abort()
    end

end

-- remove file or directory
function sandbox_builtin_os.rm(file_or_dir, emptydir)
    
    -- check
    assert(file_or_dir)

    -- done
    local ok, errors = os.rm(file_or_dir, emptydir)
    if not ok then
        utils.error(errors)
        utils.abort()
    end

end

-- change to directory
function sandbox_builtin_os.cd(dir)

    -- check
    assert(dir)

    -- done
    local ok, errors = os.cd(dir)
    if not ok then
        utils.error(errors)
        utils.abort()
    end

end

-- create directory
function sandbox_builtin_os.mkdir(dir)
    
    -- check
    assert(dir)

    -- done
    if not os.mkdir(dir) then
        utils.error("create directory: %s failed!", dir)
        utils.abort()
    end

end

-- remove directory
function sandbox_builtin_os.rmdir(dir)
    
    -- check
    assert(dir)

    -- done
    if os.isdir(dir) then
        if not os.rmdir(dir) then
            utils.error("remove directory: %s failed!", dir)
            utils.abort()
        end
    end

end

-- run shell
function sandbox_builtin_os.run(cmd, ...)

    -- make command
    cmd = string.format(cmd, ...)

    -- make temporary log file
    log = os.tmpname()

    -- run command
    if 0 ~= os.execute(cmd .. string.format(" > %s 2>&1", log)) then
        io.cat(log)
        utils.error("run: %s failed!", cmd)
        utils.abort()
    end

    -- remove the temporary log file
    os.rm(log)
end

-- register some public interfaces
sandbox_builtin_os.match    = os.match
sandbox_builtin_os.isdir    = os.isdir
sandbox_builtin_os.isfile   = os.isfile
sandbox_builtin_os.curdir   = os.curdir
sandbox_builtin_os.execute  = os.execute

-- return module
return sandbox_builtin_os

