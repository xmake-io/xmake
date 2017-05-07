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
local sandbox_core_tool_git = sandbox_core_tool_git or {}

-- load modules
local platform  = require("platform/platform")
local git       = require("tool/git")
local raise     = require("sandbox/modules/raise")

-- clone url
--
-- .e.g
-- 
-- git.clone("git@github.com:tboox/xmake.git")
-- git.clone("git@github.com:tboox/xmake.git", {depth = 1, branch = "master", outputdir = "/tmp/xmake"})
--
function sandbox_core_tool_git.clone(url, args)
 
    -- get the git instance
    local instance, errors = git.load()
    if not instance then
        raise(errors)
    end

    -- clone it
    local ok, errors = instance:clone(url, args)
    if not ok then
        raise(errors)
    end
end

-- pull remote commits
--
-- .e.g
-- 
-- git.pull()
-- git.pull({remote = "origin", tags = true, branch = "master", repodir = "/tmp/xmake"})
--
function sandbox_core_tool_git.pull(args)

    -- get the git instance
    local instance, errors = git.load()
    if not instance then
        raise(errors)
    end

    -- pull it
    local ok, errors = instance:pull(args)
    if not ok then
        raise(errors)
    end
end

-- checkout to given branch, tag or commit
--
-- .e.g
--
-- git.checkout("master", {repodir = "/tmp/xmake"})
-- git.checkout("v1.0.1", {repodir = "/tmp/xmake"})
--
function sandbox_core_tool_git.checkout(commit, args)

    -- get the git instance
    local instance, errors = git.load()
    if not instance then
        raise(errors)
    end

    -- checkout it
    local ok, errors = instance:checkout(commit, args)
    if not ok then
        raise(errors)
    end
end

-- get all tags and branches from url
--
-- .e.g
-- 
-- local tags, branches = git.refs("git@github.com:tboox/xmake.git")
--
function sandbox_core_tool_git.refs(url)

    -- get the git instance
    local instance, errors = git.load()
    if not instance then
        raise(errors)
    end

    -- get it
    local refs, errors = instance:refs(url)
    if not refs then
        raise(errors)
    end

    -- ok
    return refs.tags, refs.branches
end

-- get tags from url
--
-- .e.g
-- 
-- local tags = git.tags("git@github.com:tboox/xmake.git")
--
function sandbox_core_tool_git.tags(url)

    -- get the git instance
    local instance, errors = git.load()
    if not instance then
        raise(errors)
    end

    -- get it
    local tags, errors = instance:tags(url)
    if not tags then
        raise(errors)
    end

    -- ok
    return tags
end

-- get branches from url
--
-- .e.g
-- 
-- local branches = git.branches("git@github.com:tboox/xmake.git")
--
function sandbox_core_tool_git.branches(url)

    -- get the git instance
    local instance, errors = git.load()
    if not instance then
        raise(errors)
    end

    -- get it
    local branches, errors = instance:branches(url)
    if not branches then
        raise(errors)
    end

    -- ok
    return branches
end

-- check git url?
function sandbox_core_tool_git.checkurl(url)

    -- check it
    return git.checkurl(url)
end

-- return module
return sandbox_core_tool_git
