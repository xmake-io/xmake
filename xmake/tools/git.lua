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

-- init it
function init(shellname)

    -- save name
    _g.shellname = shellname or "git"
end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- clone url
function clone(url, args)

    -- init argv
    local argv = {"clone", url}

    -- set branch
    if args.branch then
        table.insert(argv, "-b")
        table.insert(argv, args.branch)
    end

    -- set depth
    if args.depth then
        table.insert(argv, "--depth")
        table.insert(argv, ifelse(type(args.depth) == "number", tostring(args.depth), args.depth))
    end

    -- set tags
    if args.tags then
        table.insert(argv, "--tags")
    end

    -- set outputdir
    if args.outputdir then
        table.insert(argv, args.outputdir)
    end

    -- verbose?
    local runner = os.runv
    if args.verbose then
        runner = os.execv
    end

    -- clone it
    runner(_g.shellname, argv)
end

-- pull remote commits
function pull(args)

    -- init argv
    local argv = {"pull"}

    -- set remote
    table.insert(argv, args.remote or "origin")

    -- set branch
    table.insert(argv, args.branch or "master")

    -- set tags
    if args.tags then
        table.insert(argv, "--tags")
    end

    -- enter repository directory
    local oldir = nil
    if args.repodir then
        oldir = os.cd(args.repodir)
    end

    -- verbose?
    local runner = os.runv
    if args.verbose then
        runner = os.execv
    end

    -- clone it
    runner(_g.shellname, argv)

    -- leave repository directory
    if oldir then
        os.cd(oldir)
    end
end

-- check the given flags 
function check(flags)

    -- check it
    os.run("%s --help", _g.shellname)
end
