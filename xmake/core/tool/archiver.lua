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
-- @file        archiver.lua
--

-- define module
local archiver = archiver or {}

-- load modules
local io        = require("base/io")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local sandbox   = require("sandbox/sandbox")
local platform  = require("platform/platform")
local tool      = require("tool/tool")
local archiver  = require("tool/archiver")

-- get the current tool
function archiver:_tool()

    -- get it
    return self._TOOL
end

-- load the archiver for the archive file kind
function archiver.load(kind)

    -- get it directly from cache dirst
    if archiver._INSTANCE then
        return archiver._INSTANCE
    end

    -- new instance
    local instance = table.inherit(archiver)

    -- init tool kinds
    local toolkinds =
    {
        gzip        = {"tar", "gzip"}
    ,   zip         = {"tar", "zip"}
    ,   bzip2       = {"tar"}
    ,   ["7zip"]    = {"7z"}
    ,   rar         = {}
    ,   tar         = {"tar"}
    ,   xz          = {"tar"}
    ,   lzma        = {"tar"}
    }

    -- attempt to load the archiver tool 
    local result = nil
    for _, toolkind in ipairs(toolkinds[kind] or {}) do
        result = tool.load(toolkind)
        if result then 
            break
        end
    end
    if not result then
        return nil, string.format("cannot load archiver for %s file!", kind)
    end
        
    -- save tool
    instance._TOOL = result

    -- save this instance
    archiver._INSTANCE = instance

    -- ok
    return instance
end

-- load the archiver for the archive file kind
function archiver.load_from_file(file)
    return archiver.load(unarchiver.kind_of_file(file))
end

-- archive the given file or directory
function archiver:archive(filedir, outputfile)

    -- archive it
    return sandbox.load(self:_tool().archive, path.translate(filedir), path.translate(outputfile))
end

-- return module
return archiver
