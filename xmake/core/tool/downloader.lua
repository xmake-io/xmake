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
-- @file        downloader.lua
--

-- define module
local downloader = downloader or {}

-- load modules
local table     = require("base/table")
local string    = require("base/string")
local tool      = require("tool/tool")
local sandbox   = require("sandbox/sandbox")

-- get the current tool
function downloader:_tool()

    -- get it
    return self._TOOL
end

-- load the downloader 
function downloader.load()

    -- get it directly from cache dirst
    if downloader._INSTANCE then
        return downloader._INSTANCE
    end

    -- new instance
    local instance = table.inherit(downloader)

    -- load the downloader tool 
    local result, errors = tool.load("downloader")
    if not result then 
        return nil, errors
    end
        
    -- save tool
    instance._TOOL = result

    -- save this instance
    downloader._INSTANCE = instance

    -- ok
    return instance
end

-- get properties of the tool
function downloader:get(name)

    -- get it
    return self:_tool().get(name)
end

-- download url
--
-- .e.g
--
-- downloader.load():download(url, outputfile)
-- downloader.load():download(url, outputfile, {verbose = true})
--
function downloader:download(url, outputfile, args)

    -- download it
    return sandbox.load(self:_tool().download, url, outputfile, args)
end

-- return module
return downloader
