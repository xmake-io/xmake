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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        rule.lua
--

-- define module
local rule = rule or {}

-- load modules
local os             = require("base/os")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")

-- get rule apis
function rule.apis()

    return 
    {
        values =
        {
            -- rule.add_xxx
            "rule.add_imports"
        }
    ,   script =
        {
            -- rule.on_xxx
            "rule.on_build"
        ,   "rule.on_clean"
        ,   "rule.on_package"
        ,   "rule.on_install"
        ,   "rule.on_uninstall"
            -- rule.before_xxx
        ,   "rule.before_build"
        ,   "rule.before_clean"
        ,   "rule.before_package"
        ,   "rule.before_install"
        ,   "rule.before_uninstall"
            -- rule.after_xxx
        ,   "rule.after_build"
        ,   "rule.after_clean"
        ,   "rule.after_package"
        ,   "rule.after_install"
        ,   "rule.after_uninstall"
            -- rule.on_xxx_all
        ,   "rule.on_build_all"
        ,   "rule.on_clean_all"
        ,   "rule.on_package_all"
        ,   "rule.on_install_all"
        ,   "rule.on_uninstall_all"
            -- rule.before_xxx_all
        ,   "rule.before_build_all"
        ,   "rule.before_clean_all"
        ,   "rule.before_package_all"
        ,   "rule.before_install_all"
        ,   "rule.before_uninstall_all"
            -- rule.after_xxx_all
        ,   "rule.after_build_all"
        ,   "rule.after_clean_all"
        ,   "rule.after_package_all"
        ,   "rule.after_install_all"
        ,   "rule.after_uninstall_all"
        }
    }
end

-- new a rule instance
function rule.new(name, info)

    -- init a rule instance
    local instance = table.inherit(rule)
    assert(instance)

    -- save name and info
    instance._NAME = name
    instance._INFO = info

    -- ok?
    return instance
end

-- get the rule info
function rule:get(name)
    return self._INFO[name]
end


-- return module
return rule
