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
-- @file        path.lua
--

-- define module: path
local path = path or {}

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")

-- get the directory of the path
function path.directory(p)
    local i = p:find_last("[/\\]")
    if i then
        if i > 1 then i = i - 1 end
        return p:sub(1, i)
    else
        return "."
    end
end

-- get the filename of the path
function path.filename(p)
    local i = p:find_last("[/\\]")
    if i then
        return p:sub(i + 1)
    else
        return p
    end
end

-- get the basename of the path
function path.basename(p)
    local name = path.filename(p)
    local i = name:find_last(".", true)
    if i then
        return name:sub(1, i - 1)
    else
        return name
    end
end

-- get the file extension of the path: .xxx
function path.extension(p)

    -- check
    assert(p)

    -- get extension
    local i = p:find_last(".", true)
    if i then
        return p:sub(i)
    else
        return ""
    end
end

-- join path
function path.join(p, ...)

    -- check
    assert(p)

    -- join them
    for _, name in ipairs({...}) do
        p = p .. "/" .. name
    end

    -- translate path
    return path.translate(p)
end

-- split path by the separator
function path.split(p)

    -- split it
    return p:split("/\\")
end

-- get the path seperator
function path.seperator()

    -- windows?
    if xmake._HOST == "windows" then
        return '\\'
    else
        return '/'
    end
end

-- return module: path
return path
