--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
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

    -- load configs
    self:load(not option.get("clean"))
end

-- get menu config dialog
function app:mconfdialog()
    if not self._MCONFDIALOG then
        local mconfdialog = mconfdialog:new("app.config.mconfdialog", rect{1, 1, self:width() - 1, self:height() - 1}, "menu config")
        mconfdialog:action_set(action.ac_on_exit, function (v)
            self:quit()
            os.exit()
        end)
        mconfdialog:action_set(action.ac_on_save, function (v)
            self:save()
            self:quit()
        end)
        self._MCONFDIALOG = mconfdialog
    end
    return self._MCONFDIALOG
end

-- on resize
function app:on_resize()
    self:mconfdialog():bounds_set(rect{1, 1, self:width() - 1, self:height() - 1})
    application.on_resize(self)
end

-- filter option
function app:_filter_option(name)
    local options =
    {
        target      = true
    ,   file        = true
    ,   root        = true
    ,   yes         = true
    ,   quiet       = true
    ,   confirm     = true
    ,   project     = true
    ,   verbose     = true
    ,   diagnosis   = true
    ,   require     = true
    ,   version     = true
    ,   help        = true
    ,   clean       = true
    ,   menu        = true
    }
    return not options[name] and not project.option(name)
end

-- get or make menu by category
function app:_menu_by_category(root, configs, menus, category)

    -- is root?
    if category == "." or category == "" then
        return
    end

    -- attempt to get menu first
    local menu = menus[category]
    if not menu then

        -- get config path
        local parentdir = path.directory(category)
        local config_path = path.join(root, parentdir == "." and "" or parentdir)

        -- make a new menu
        menu = menuconf.menu {name = category, path = config_path, description = path.basename(category), configs = {}}
        menus[category] = menu

        -- insert to the parent or root configs
        local parent = self:_menu_by_category(root, configs, menus, parentdir)
        table.insert(parent and parent.configs or configs, menu)
    end
    return menu
end

-- make configs by category
function app:_make_configs_by_category(root, options_by_category, cache, get_option_info)

    -- make configs category
    --
    -- root category: "."
    -- category path: "a", "a/b", "a/b/c" ...
    --
    local menus = {}
    local configs = {}
    for category, options in pairs(options_by_category) do

        -- get or make menu by category
        local menu = self:_menu_by_category(root, configs, menus, category)

        -- get sub-configs
        local subconfigs = menu and menu.configs or configs

        -- insert options to sub-configs
        for _, opt in ipairs(options) do

            -- get option info
            local info = get_option_info(opt)

            -- new value?
            local newvalue = true

            -- load value
            local value = nil
            if cache then
                value = config.get(info.name)
                if value ~= nil and info.kind == "choice" and info.values then
                    for idx, val in ipairs(info.values) do
                        if value == val then
                            value = idx
                            break
                        end
                    end
                end
                if value ~= nil then
                    newvalue = false
                end
            end

            -- find the menu index in subconfigs
            local menu_index = #subconfigs + 1
            for idx, subconfig in ipairs(subconfigs) do
                if subconfig.kind == "menu" then
                    menu_index = idx
                    break
                end
            end

            -- get config path
            local config_path = path.join(root, category == "." and "" or category)

            -- insert config before all sub-menus
            if info.kind == "string" then
                table.insert(subconfigs, menu_index, menuconf.string {name = info.name, value = value, new = newvalue, default = info.default, path = config_path, description = info.description, sourceinfo = info.sourceinfo})
            elseif info.kind == "boolean" then
                table.insert(subconfigs, menu_index, menuconf.boolean {name = info.name, value = value, new = newvalue, default = info.default, path = config_path, description = info.description, sourceinfo = info.sourceinfo})
            elseif info.kind == "choice" then
                table.insert(subconfigs, menu_index, menuconf.choice {name = info.name, value = value, new = newvalue, default = info.default, path = config_path, values = info.values, description = info.description, sourceinfo = info.sourceinfo})
            end
        end
    end

    -- done
    return configs
end

-- get basic configs
function app:_basic_configs(cache)

    -- get configs from the cache first
    local configs = self._BASIC_CONFIGS
    if configs then
        return configs
    end

    -- get config menu
    local menu = option.taskmenu("config")

    -- merge options by category
    local category = "."
    local options = menu and menu.options or {}
    local options_by_category = {}
    for _, opt in pairs(options) do
        local name = opt[2] or opt[1]
        if name and self:_filter_option(name) then
            options_by_category[category] = options_by_category[category] or {}
            table.insert(options_by_category[category], opt)
        elseif opt.category then
            category = opt.category
        end
    end

    -- make configs by category
    self._BASIC_CONFIGS = self:_make_configs_by_category("Basic Configuration", options_by_category, cache, function (opt)

        -- get default
        local default = opt[4]

        -- get kind
        local kind = (opt[3] == "k" or type(default) == "boolean") and "boolean" or "string"

        -- choice option?
        local values = opt.values
        if values then
            if type(values) == "function" then
                values = values()
            end
            for idx, value in ipairs(values) do
                if default == value then
                    default = idx
                    break
                end
            end
        end
        if values then
            kind = "choice"
        end

        -- get description
        local description = {}
        for i = 5, 64 do
            local desc = opt[i]
            if type(desc) == "function" then
                desc = desc()
            end
            if type(desc) == "string" then
                table.insert(description, desc)
            elseif type(desc) == "table" then
                table.join2(description, desc)
            else
                break
            end
        end

        -- make option info
        return {name = opt[2] or opt[1], kind = kind, default = default, values = values, description = description}
    end)
    return self._BASIC_CONFIGS
end

-- get project configs
function app:_project_configs(cache)

    -- get configs from the cache first
    local configs = self._PROJECT_CONFIGS
    if configs then
        return configs
    end

    -- merge options by category
    local options = project.options()
    local options_by_category = {}
    for _, opt in pairs(options) do
        if opt:get("showmenu") then
            local category = "."
            if opt:get("category") then category = table.unwrap(opt:get("category")) end
            options_by_category[category] = options_by_category[category] or {}
            table.insert(options_by_category[category], opt)
        end
    end

    -- make configs by category
    self._PROJECT_CONFIGS = self:_make_configs_by_category("Project Configuration", options_by_category, cache, function (opt)

        -- the default value
        local default = "auto"
        if opt:get("default") ~= nil then
            default = opt:get("default")
        end

        -- get kind
        local kind = (type(default) == "string") and "string" or "boolean"

        -- get description
        local description = opt:get("description")

        -- get source info
        local sourceinfo = (opt:get("__sourceinfo_description") or {})[type(description) == "table" and description[1] or description]

        -- choice option?
        local values = opt:get("values")
        if values then
            kind = "choice"
            for idx, value in ipairs(values) do
                if default == value then
                    default = idx
                    break
                end
            end
        end
        return {name = opt:name(), kind = kind, default = default, values = values, description = description, sourceinfo = sourceinfo}
    end)
    return self._PROJECT_CONFIGS
end

-- save the given configs
function app:_save_configs(configs)
    local options = option.options()
    for _, conf in pairs(configs) do
        if conf.kind == "menu" then
            self:_save_configs(conf.configs)
        elseif not conf.new and (conf.kind == "boolean" or conf.kind == "string") then
            options[conf.name] = conf.value
        elseif not conf.new and (conf.kind == "choice") then
            options[conf.name] = conf.values[conf.value]
        end
    end
end

-- load configs from options
function app:load(cache)

    -- load config from cache
    if cache then
        cache = config.load(option.get("target") or "all")
    end

    -- clear configs first
    self._BASIC_CONFIGS = nil
    self._PROJECT_CONFIGS = nil

    -- load configs
    local configs = {}
    table.insert(configs, menuconf.menu {description = "Basic Configuration", configs = self:_basic_configs(cache)})
    table.insert(configs, menuconf.menu {description = "Project Configuration", configs = self:_project_configs(cache)})
    self:mconfdialog():load(configs)

    -- the previous config is only for loading menuconf, so clear config now
    if cache then
        config.clear()
    end
end

-- save configs to options
function app:save()
    self:_save_configs(self:_basic_configs())
    self:_save_configs(self:_project_configs())
end

-- main entry
function main(...)
    app:run(...)
end
