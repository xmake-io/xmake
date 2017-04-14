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
-- @file        git.lua
--

-- define module
local git = git or {}

-- load modules
local os        = require("base/os")
local table     = require("base/table")
local string    = require("base/string")
local tool      = require("tool/tool")
local sandbox   = require("sandbox/sandbox")

-- get the current tool
function git:_tool()

    -- get it
    return self._TOOL
end

-- check git url?
function git.checkurl(url)

    -- check it
    return url:endswith(".git") or os.isdir(url .. ".git")
end

-- load the git 
function git.load()

    -- get it directly from cache dirst
    if git._INSTANCE then
        return git._INSTANCE
    end

    -- new instance
    local instance = table.inherit(git)

    -- load the git tool 
    local result, errors = tool.load("git")
    if not result then 
        return nil, errors
    end
        
    -- save tool
    instance._TOOL = result

    -- save this instance
    git._INSTANCE = instance

    -- ok
    return instance
end

-- get properties of the tool
function git:get(name)

    -- get it
    return self:_tool().get(name)
end

-- clone url
--
-- .e.g
-- 
-- git.load():clone("git@github.com:tboox/xmake.git")
-- git.load():clone("git@github.com:tboox/xmake.git", {verbose = true, tags = true, depth = 1, branch = "master", outputdir = "/tmp/xmake"})
--
function git:clone(url, args)

    -- clone it
    return sandbox.load(self:_tool().clone, url, args)
end

-- pull remote commits
--
-- .e.g
-- 
-- git.load():pull()
-- git.load():pull({verbose = true, remote = "origin", tags = true, branch = "master", repodir = "/tmp/xmake"})
--
function git:pull(args)

    -- pull it
    return sandbox.load(self:_tool().pull, args)
end

-- get tags from url
function git:tags(url)

    -- get it
    local ok, tags_or_errors = sandbox.load(self:_tool().ls_remote, "tags", url)
    if not ok then
        return nil, tags_or_errors
    end

    -- ok
    return tags_or_errors
end

-- get branchs from url
function git:branches(url)

    -- get it
    local ok, branches_or_errors = sandbox.load(self:_tool().ls_remote, "heads", url)
    if not ok then
        return nil, branches_or_errors
    end

    -- ok
    return branches_or_errors
end

-- get all refs from url, contains tags and branchs 
function git:refs(url)

    -- get it
    local ok, refs_or_errors = sandbox.load(self:_tool().ls_remote, "refs", url)
    if not ok then
        return nil, refs_or_errors
    end

    -- get tags and branches
    local tags = {}
    local branches = {}
    for _, ref in ipairs(refs_or_errors) do
        if ref:startswith("tags/") then
            table.insert(tags, ref:sub(6))
        elseif ref:startswith("heads/") then
            table.insert(tags, ref:sub(7))
        end
    end

    -- ok
    return {tags = tags, branches = branches}
end

-- return module
return git
