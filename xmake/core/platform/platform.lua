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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        platform.lua
--

-- define module
local platform      = platform or {}
local _instance     = _instance or {}

-- load modules
local os             = require("base/os")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local global         = require("base/global")
local interpreter    = require("base/interpreter")
local toolchain      = require("tool/toolchain")
local memcache       = require("cache/memcache")
local sandbox        = require("sandbox/sandbox")
local config         = require("project/config")
local scheduler      = require("sandbox/modules/import/core/base/scheduler")

-- new an instance
function _instance.new(name, info, opt)
    opt = opt or{}
    local instance    = table.inherit(_instance)
    instance._NAME    = name
    instance._INFO    = info
    instance._ARCH    = opt.arch
    instance._IS_HOST = opt.host or false
    return instance
end

-- get memcache
function _instance:_memcache()
    local cache = self._MEMCACHE
    if not cache then
        cache = memcache.cache("core.platform.platform." .. tostring(self))
        self._MEMCACHE = cache
    end
    return cache
end

-- the toolchains cache key for names
function _instance:_toolchains_key()
    return "__toolchains_" .. self:name() .. "_" .. self:arch() .. (self:is_host() and "_host" or "")
end

-- get platform name
function _instance:name()
    return self._NAME
end

-- get platform architecture
function _instance:arch()
    return self._ARCH or config.get("arch")
end

-- set platform architecture
function _instance:arch_set(arch)
    if self:arch() ~= arch then
        -- we need to clean the dirty cache if architecture has been changed
        platform._PLATFORMS[self:name() .. "_" .. self:arch()] = nil
        platform._PLATFORMS[self:name() .. "_" .. arch] = self
        self._ARCH = arch
    end
end

-- is host platform, it will use the host toolchain
function _instance:is_host()
    return self._IS_HOST
end

-- set the value to the platform configuration
function _instance:set(name, ...)
    self._INFO:apival_set(name, ...)
end

-- add the value to the platform configuration
function _instance:add(name, ...)
    self._INFO:apival_add(name, ...)
end

-- get the platform configuration
function _instance:get(name)

    -- attempt to get the static configure value
    local value = self._INFO:get(name)
    if value ~= nil then
        return value
    end

    -- lazy loading platform if get other configuration
    if not self._LOADED and not self:_is_builtin_conf(name) then
        local on_load = self._INFO:get("load")
        if on_load then
            local ok, errors = sandbox.load(on_load, self)
            if not ok then
                os.raise(errors)
            end
        end
        self._LOADED = true
    end

    -- get other platform info
    return self._INFO:get(name)
end

-- get the platform os
function _instance:os()
    return self._INFO:get("os")
end

-- get the platform menu
function _instance:menu()
    -- @note do not use self:get("menu") to avoid loading platform early
    return self._INFO:get("menu")
end

-- get the platform hosts
function _instance:hosts()
    return self._INFO:get("hosts")
end

-- get the platform archs
function _instance:archs()
    return self._INFO:get("archs")
end

-- get runenvs of toolchains
function _instance:runenvs()
    local runenvs = self._RUNENVS
    if not runenvs then
        runenvs = {}
        for _, toolchain_inst in ipairs(self:toolchains()) do
            local toolchain_runenvs = toolchain_inst:get("runenvs")
            if toolchain_runenvs then
                for name, values in pairs(toolchain_runenvs) do
                    runenvs[name] = table.join2(table.wrap(runenvs[name]), values)
                end
            end
        end
        self._RUNENVS = runenvs
    end
    return runenvs
end

-- get the toolchains
function _instance:toolchains(opt)
    local toolchains = self:_memcache():get("toolchains")
    if not toolchains then

        -- get current valid toolchains from configuration cache
        local names = nil
        toolchains = {}
        if not (opt and opt.all) then
            names = config.get(self:_toolchains_key())
        end
        if not names then
            -- get the given toolchain
            local toolchain_given = config.get(self:is_host() and "toolchain_host" or "toolchain")
            if toolchain_given then
                local toolchain_inst, errors = toolchain.load(toolchain_given, {
                    plat = self:name(), arch = self:arch()})
                -- attempt to load toolchain from project
                if not toolchain_inst and platform._project() then
                    toolchain_inst = platform._project().toolchain(toolchain_given)
                end
                if not toolchain_inst then
                    os.raise(errors)
                end
                table.insert(toolchains, toolchain_inst)
                toolchain_given = toolchain_inst
            end

            -- get the platform toolchains
            if (not toolchain_given or not toolchain_given:is_standalone()) and self._INFO:get("toolchains") then
                names = self._INFO:get("toolchains")
            end
        end
        if names then
            for _, name in ipairs(table.wrap(names)) do
                local toolchain_inst, errors = toolchain.load(name, {
                    plat = self:name(), arch = self:arch()})
                -- attempt to load toolchain from project
                if not toolchain_inst and platform._project() then
                    toolchain_inst = platform._project().toolchain(name)
                end
                if not toolchain_inst then
                    os.raise(errors)
                end
                -- ignore cross toolchains for the host platform:w
                if (self:is_host() and not toolchain_inst:is_cross()) or not self:is_host() then
                    table.insert(toolchains, toolchain_inst)
                end
            end
        end
        self:_memcache():set("toolchains", toolchains)
    end
    return toolchains
end

-- get the program and name of the given tool kind
function _instance:tool(toolkind)
    return toolchain.tool(self:toolchains(), toolkind, {cachekey = "platform", plat = self:name(), arch = self:arch(),
                          before_get = function ()
        return config.get(toolkind)
    end})
end

-- get tool configuration from the toolchains
function _instance:toolconfig(name)
    return toolchain.toolconfig(self:toolchains(), name, {cachekey = "platform", plat = self:name(), arch = self:arch()})
end

-- get the platform script
function _instance:script(name)
    return self._INFO:get(name)
end

-- get user private data
function _instance:data(name)
    return self._DATA and self._DATA[name] or nil
end

-- set user private data
function _instance:data_set(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = data
end

-- add user private data
function _instance:data_add(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = table.unwrap(table.join(self._DATA[name] or {}, data))
end

-- do check
function _instance:check()
    -- @see https://github.com/xmake-io/xmake/issues/4645#issuecomment-2201036943
    -- @note avoid check it in the same time leading to deadlock if running in the coroutine
    local lockname = tostring(self)
    scheduler.co_lock(lockname)

    -- this platform has been check?
    local checked = self:_memcache():get("checked")
    if checked ~= nil then
        scheduler.co_unlock(lockname)
        return checked
    end

    -- check toolchains
    local toolchains = self:toolchains({all = true})
    local idx = 1
    local num = #toolchains
    local standalone = false
    local toolchains_valid = {}
    while idx <= num do
        local toolchain = toolchains[idx]
        -- we need to remove other standalone toolchains if standalone toolchain found
        if (standalone and toolchain:is_standalone()) or not toolchain:check() then
            table.remove(toolchains, idx)
            num = num - 1
        else
            if toolchain:is_standalone() then
                standalone = true
            end
            idx = idx + 1
            table.insert(toolchains_valid, toolchain:name())
        end
    end
    if #toolchains == 0 then
        self:_memcache():set("checked", false)
        scheduler.co_unlock(lockname)
        return false, "toolchains not found!"
    end

    -- save valid toolchains
    config.set(self:_toolchains_key(), toolchains_valid)
    self:_memcache():set("checked", true)
    scheduler.co_unlock(lockname)
    return true
end

-- get formats
function _instance:formats()
    local formats = self._FORMATS
    if not formats then
        for _, toolchain_inst in ipairs(self:toolchains()) do
            -- @note we can only get formats from set_formats in toolchain description.
            formats = toolchain_inst:get("formats", {load = false})
            if formats then
                break
            end
        end
        if not formats then
            formats = self._INFO:get("formats")
        end
        self._FORMATS = formats
    end
    return formats
end

-- is builtin configuration?
function _instance:_is_builtin_conf(name)

    local builtin_configs = self._BUILTIN_CONFIGS
    if not builtin_configs then
        builtin_configs = {}
        for apiname, _ in pairs(platform._interpreter():apis("platform")) do
            local pos = apiname:find('_', 1, true)
            if pos then
                builtin_configs[apiname:sub(pos + 1)] = true
            end
        end
        self._BUILTIN_CONFIGS = builtin_configs
    end
    return builtin_configs[name]
end

-- the interpreter
function platform._interpreter()

    -- the interpreter has been initialized? return it directly
    if platform._INTERPRETER then
        return platform._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)

    -- define apis
    interp:api_define(platform._apis())

    -- save interpreter
    platform._INTERPRETER = interp

    -- ok?
    return interp
end

-- get project
function platform._project()
    return platform._PROJECT
end

-- get platform apis
function platform._apis()
    return
    {
        values =
        {
            -- platform.set_xxx
            "platform.set_os"
        ,   "platform.set_hosts"
        ,   "platform.set_archs"
        ,   "platform.set_installdir"
        ,   "platform.set_toolchains"
        }
    ,   script =
        {
            -- platform.on_xxx
            "platform.on_load"
        }
    ,   keyvalues =
        {
            "platform.set_formats"
        }
    ,   dictionary =
        {
            -- platform.set_xxx
            "platform.set_menu"
        }
    }
end

-- get memcache
function platform._memcache()
    return memcache.cache("core.platform.platform")
end

-- get platform directories
function platform.directories()
    local dirs = platform._DIRS or  {   path.join(global.directory(), "platforms")
                                    ,   path.join(os.programdir(), "platforms")
                                    }
    platform._DIRS = dirs
    return dirs
end

-- add platform directories
function platform.add_directories(...)
    local dirs = platform.directories()
    for _, dir in ipairs({...}) do
        table.insert(dirs, 1, dir)
    end
    platform._DIRS = table.unique(dirs)
end

-- load the given platform
function platform.load(plat, arch, opt)
    opt = opt or {}
    plat = plat or config.get("plat") or os.host()
    arch = arch or config.get("arch") or os.arch()

    -- get cache key
    local cachekey = plat .. "_" .. arch
    if opt.host then
        cachekey = cachekey .. "_host"
    end

    -- get it directly from cache dirst
    platform._PLATFORMS = platform._PLATFORMS or {}
    if platform._PLATFORMS[cachekey] then
        return platform._PLATFORMS[cachekey]
    end

    -- find the platform script path
    local scriptpath = nil
    for _, dir in ipairs(platform.directories()) do
        scriptpath = path.join(dir, plat, "xmake.lua")
        if os.isfile(scriptpath) then
            break
        end
    end

    -- unknown platform? switch to cross compilation platform
    local cross = false
    if not scriptpath or not os.isfile(scriptpath) then
        scriptpath = path.join(os.programdir(), "platforms", "cross", "xmake.lua")
        cross = true
    end

    -- not exists?
    if not scriptpath or not os.isfile(scriptpath) then
        return nil, string.format("the platform %s not found!", plat)
    end

    -- get interpreter
    local interp = platform._interpreter()

    -- load script
    local ok, errors = interp:load(scriptpath)
    if not ok then
        return nil, errors
    end

    -- load platform
    local results, errors = interp:make("platform", true, false)
    if not results and os.isfile(scriptpath) then
        return nil, errors
    end

    -- get result
    local result = cross and results["cross"] or results[plat]

    -- check the platform name
    if not result then
        return nil, string.format("the platform %s not found!", plat)
    end

    -- save instance to the cache
    local instance = _instance.new(plat, result, {arch = arch, host = opt.host})
    platform._PLATFORMS[cachekey] = instance
    return instance
end

-- get the given platform configuration
function platform.get(name, plat, arch, opt)
    local instance, errors = platform.load(plat, arch, opt)
    if instance then
        return instance:get(name)
    else
        os.raise(errors)
    end
end

-- get the platform tool from the kind
--
-- e.g. cc, cxx, mm, mxx, as, ar, ld, sh, ..
--
function platform.tool(toolkind, plat, arch, opt)
    local instance, errors = platform.load(plat, arch, opt)
    if instance then
        return instance:tool(toolkind)
    else
        os.raise(errors)
    end
end

-- get the given tool configuration
function platform.toolconfig(name, plat, arch, opt)
    local instance, errors = platform.load(plat, arch, opt)
    if instance then
        return instance:toolconfig(name)
    else
        os.raise(errors)
    end
end

-- get the all platforms
function platform.plats()

    -- return it directly if exists
    if platform._PLATS then
        return platform._PLATS
    end

    -- get all platforms
    local plats = {}
    local dirs  = platform.directories()
    for _, dir in ipairs(dirs) do
        local platpathes = os.dirs(path.join(dir, "*"))
        if platpathes then
            for _, platpath in ipairs(platpathes) do
                if os.isfile(path.join(platpath, "xmake.lua")) then
                    table.insert(plats, path.basename(platpath))
                end
            end
        end
    end
    platform._PLATS = plats
    return plats
end

-- get the all toolchains
function platform.toolchains()
    local toolchains = platform._memcache():get("toolchains")
    if not toolchains then
        toolchains = {}
        local dirs  = toolchain.directories()
        for _, dir in ipairs(dirs) do
            local dirs = os.dirs(path.join(dir, "*"))
            if dirs then
                for _, dir in ipairs(dirs) do
                    if os.isfile(path.join(dir, "xmake.lua")) then
                        table.insert(toolchains, path.filename(dir))
                    end
                end
            end
        end
        platform._memcache():set("toolchains", toolchains)
    end
    return toolchains
end

-- get the platform os
function platform.os(plat, arch)
    return platform.get("os", plat, arch) or config.get("target_os")
end

-- get the platform archs
function platform.archs(plat, arch)
    return platform.get("archs", plat, arch)
end

-- get the format of the given kind for platform
function platform.format(kind, plat, arch)

    -- get platform instance
    local instance, errors = platform.load(plat, arch)
    if not instance then
        os.raise(errors)
    end

    -- get formats
    local formats = instance:formats()
    if formats then
        return formats[kind]
    end
end


-- return module
return platform
