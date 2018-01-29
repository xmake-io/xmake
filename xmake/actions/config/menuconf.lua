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
-- @file        menuconf.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.ui.log")
import("core.ui.rect")
import("core.ui.view")
import("core.ui.label")
import("core.ui.event")
import("core.ui.action")
import("core.ui.menuconf")
import("core.ui.mconfdialog")
import("core.ui.application")

-- the app application
local app = application()

-- init app
function app:init()

    -- init name 
    application.init(self, "app.config")

    -- init background
    self:background_set("blue")

    -- insert menu config dialog
    self:insert(self:mconfdialog())
end

-- get menu config dialog
function app:mconfdialog()
    if not self._MCONFDIALOG then
        local mconfdialog = mconfdialog:new("app.config.mconfdialog", rect {1, 1, self:width() - 1, self:height() - 1}, "menu config")
        mconfdialog:action_set(action.ac_on_exit, function (v) self:quit() end)
        mconfdialog:action_set(action.ac_on_load, function (v) 
            self:load()
        end)
        mconfdialog:action_set(action.ac_on_save, function (v) 
            self:save()
            mconfdialog:quit()
        end)
        self._MCONFDIALOG = mconfdialog
    end
    return self._MCONFDIALOG
end

-- get basic configs 
function app:basic_configs()
    
    -- get configs from the cache first 
    local configs = self._BASIC_CONFIGS
    if configs then
        return configs
    end

    -- get config menu
    local menu = option.taskmenu("config")

    -- make configs from options
    local configs = {}
    local options = menu and menu.options or {}
    for _, opt in ipairs(options) do

        -- get name
        local name = opt[2] or opt[1]

        -- get kind
        local kind = opt[3]

        -- get default
        local default = opt[4]

        -- get description
        local description = opt[5]

        -- key=value?
        if kind == "kv" then
            table.insert(configs, menuconf.string {name = name, default = default, description = description})
        elseif kind == "k" then
            table.insert(configs, menuconf.boolean {name = name, default = default, description = description})
        end
    end

    -- cache configs
    self._BASIC_CONFIGS = configs
    return configs
end

-- get project configs 
function app:project_configs()
 
    -- get configs from the cache first 
    local configs = self._PROJECT_CONFIGS
    if configs then
        return configs
    end

    -- TODO

    -- cache configs
    self._PROJECT_CONFIGS = configs
    return configs
end

-- load configs from options
function app:load()

    -- load configs
    local configs = {}
    table.insert(configs, menuconf.menu {description = "Basic Configuration", configs = self:basic_configs()})
    table.insert(configs, menuconf.menu {description = "Project Configuration", configs = self:project_configs()})
    self:mconfdialog():load(configs)
end

-- save configs to options
function app:save()
end

-- main entry
function main(...)
    app:run(...)
end
