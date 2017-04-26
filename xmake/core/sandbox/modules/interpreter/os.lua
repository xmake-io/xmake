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
local os        = require("base/os")
local string    = require("base/string")

-- define module
local sandbox_os = sandbox_os or {}

-- export some readonly interfaces
sandbox_os.date     = os.date
sandbox_os.time     = os.time
sandbox_os.mtime    = os.mtime
sandbox_os.mclock   = os.mclock
sandbox_os.getenv   = os.getenv
sandbox_os.isdir    = os.isdir
sandbox_os.isfile   = os.isfile
sandbox_os.exists   = os.exists
sandbox_os.curdir   = os.curdir
sandbox_os.tmpdir   = os.tmpdir
sandbox_os.uuid     = os.uuid

-- match files
function sandbox_os.files(pattern, ...)
    return os.files(string.format(pattern, ...))
end

-- match directories
function sandbox_os.dirs(pattern, ...)
    return os.dirs(string.format(pattern, ...))
end

-- match file and directories
function sandbox_os.filedirs(pattern, ...)
    return os.filedirs(string.format(pattern, ...))
end

-- get the system host
function sandbox_os.host()
    return xmake._HOST
end

-- get the system architecture
function sandbox_os.arch()
    return xmake._ARCH
end

-- return module
return sandbox_os

