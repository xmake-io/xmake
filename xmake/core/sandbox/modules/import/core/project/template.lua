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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        template.lua
--

-- define module
local sandbox_core_project_template = sandbox_core_project_template or {}

-- load modules
local template  = require("project/template")
local raise     = require("sandbox/modules/raise")

-- get all languages
function sandbox_core_project_template.languages()

    -- get it 
    local languages = template.languages()
    assert(languages)

    -- ok
    return languages
end

-- load all templates from the given language 
function sandbox_core_project_template.templates(language)

    -- get it 
    local templates = template.templates(language)
    assert(templates)

    -- ok
    return templates
end

-- create project from template
function sandbox_core_project_template.create(language, templateid, targetname)

    -- create it
    local ok, errors = template.create(language, templateid, targetname)
    if not ok then
        raise(errors)
    end
end

-- get FAQ
function sandbox_core_project_template.faq()
    return template.faq()
end

-- return module
return sandbox_core_project_template
