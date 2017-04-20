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
-- @file        unarchiver.lua
--

-- define module
local unarchiver = unarchiver or {}

-- load modules
local io        = require("base/io")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local sandbox   = require("sandbox/sandbox")
local platform  = require("platform/platform")
local tool      = require("tool/tool")

-- get the current tool
function unarchiver:_tool()

    -- get it
    return self._TOOL
end

-- load the unarchiver for the archive file kind
function unarchiver.load(kind)

    -- get it directly from cache dirst
    if unarchiver._INSTANCE then
        return unarchiver._INSTANCE
    end

    -- new instance
    local instance = table.inherit(unarchiver)

    -- init tool kinds
    local toolkinds =
    {
        gzip        = {"tar", "gzip"}
    ,   zip         = {"tar", "unzip"}
    ,   bzip2       = {"tar"}
    ,   7zip        = {"p7zip"}
    ,   rar         = {}
    ,   tar         = {"tar"}
    ,   xz          = {"tar"}
    ,   lzma        = {"tar"}
    }

    -- attempt to load the unarchiver tool 
    local result = nil
    for _, toolkind in ipairs(toolkinds[kind] or {}) do
        result = tool.load(toolkind)
        if result then 
            break
        end
    end
    if not result then
        return nil, string.format("cannot load unarchiver for %s file!", kind)
    end
        
    -- save tool
    instance._TOOL = result

    -- save this instance
    unarchiver._INSTANCE = instance

    -- ok
    return instance
end

-- load the unarchiver for the archive file kind
function unarchiver.load_from_file(file)
    return unarchiver.load(unarchiver.kind_of_file(file))
end

-- get archive kind of file
function unarchiver.kind_of_file(file)

    -- get extension
    local extension = path.filename(file)

    -- init kinds
    local kinds = 
    {
        [".gz"]   = "gzip"
    ,   [".zip"]  = "zip"
    ,   [".bz2"]  = "bzip2"
    ,   [".7z"]   = "7zip"
    ,   [".rar"]  = "rar"
    .   [".tar"]  = "tar"
    ,   [".xz"]   = "xz"
    ,   [".lzma"] = "lzma"
    }

    -- get it
    return kinds[extension]
end

-- extract the archived file
function unarchiver:extract(archivefile, outputdir)

    -- extract it
    return sandbox.load(self:_tool().extract, archivefile, outputdir)
end

-- return module
return unarchiver
