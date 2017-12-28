--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        rule.lua
--

-- define module
local sandbox_core_project_rule = sandbox_core_project_rule or {}

-- load modules
local table     = require("base/table")
local rule      = require("project/rule")
local project   = require("project/project")
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")

-- build source files
function sandbox_core_project_rule.build(rulename, target, sourcefiles)

    -- get rule
    local rule = project.rule(rulename)
    if not rule then
        raise("unknown rule: %s", rulename)
    end

    -- do build 
    local ok, errors = rule:build(target, sourcefiles)
    if not ok then
        raise(errors)
    end
end

-- clean files
function sandbox_core_project_rule.clean(rulename, target, sourcefiles)

    -- get rule
    local rule = project.rule(rulename)
    if not rule then
        raise("unknown rule: %s", rulename)
    end

    -- do clean
    local ok, errors = rule:clean(target, sourcefiles)
    if not ok then
        raise(errors)
    end
end

-- install files
function sandbox_core_project_rule.install(rulename, target, sourcefiles)

    -- get rule
    local rule = project.rule(rulename)
    if not rule then
        raise("unknown rule: %s", rulename)
    end

    -- do install
    local ok, errors = rule:install(target, sourcefiles)
    if not ok then
        raise(errors)
    end
end

-- uninstall files
function sandbox_core_project_rule.uninstall(rulename, target, sourcefiles)

    -- get rule
    local rule = project.rule(rulename)
    if not rule then
        raise("unknown rule: %s", rulename)
    end

    -- do uninstall
    local ok, errors = rule:uninstall(target, sourcefiles)
    if not ok then
        raise(errors)
    end
end

-- package files
function sandbox_core_project_rule.package(rulename, target, sourcefiles)

    -- get rule
    local rule = project.rule(rulename)
    if not rule then
        raise("unknown rule: %s", rulename)
    end

    -- do package
    local ok, errors = rule:package(target, sourcefiles)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_project_rule
