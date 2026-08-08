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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        addon.lua
--

-- define module
local addon = addon or {}

-- load modules
local os     = require("base/os")
local io     = require("base/io")
local path   = require("base/path")
local table  = require("base/table")
local utils  = require("base/utils")
local global = require("base/global")

-- the payload directories of an addon
--
-- an addon can provide any subset of them, e.g. only `plugins`
--
-- @note only `plugins` is activated for now, the others are reserved
--
function addon.payloaddirs()
    return {"plugins", "rules", "toolchains", "platforms", "modules", "templates", "themes", "includes"}
end

-- the install directory of addons, e.g. ~/.xmake/addons
function addon.installdir()
    return path.join(global.directory(), "addons")
end

-- get the directory name of the given addon name, e.g. "myns::foo" -> "myns_foo"
function addon.dirname(name)
    return (name:lower():gsub("::", "_"))
end

-- the registry file of the installed addons, e.g. ~/.xmake/addons/addons.conf
--
-- we save all installed addons to this file when installing/removing them,
-- so we do not need to scan the whole addons directory on startup
--
function addon.registryfile()
    return path.join(addon.installdir(), "addons.conf")
end

-- get all installed addons
--
-- @return      the addons table, e.g. {["hello-world"] = {version = "latest", payloads = {"plugins"}}}
--
function addon.addons()
    local addons = addon._ADDONS
    if addons == nil then
        addons = {}
        local registryfile = addon.registryfile()
        if os.isfile(registryfile) then
            addons = io.load(registryfile) or {}
        end
        addon._ADDONS = addons
    end
    return addons
end

-- get the install directory of the given addon, e.g. ~/.xmake/addons/<name>/<version>
function addon.addondir(name, version)
    local dirname = addon.dirname(name)
    if version == nil then
        local addoninfo = addon.addons()[dirname]
        if addoninfo == nil then
            return nil
        end
        version = addoninfo.version
    end
    return path.join(addon.installdir(), dirname, version)
end

-- get the payload directories of the given kind from all installed addons
--
-- @param kind  the payload kind, e.g. "plugins", "rules"
-- @return      the directories, e.g. {"~/.xmake/addons/hello-world/latest/plugins"}
--
-- @note we do not check if these directories exist, the callers will just ignore the invalid ones
--
function addon.payloads(kind)
    local payloads = {}
    for _, payloadinfo in ipairs(addon.payloadinfos(kind)) do
        table.insert(payloads, payloadinfo.dir)
    end
    return payloads
end

-- get the payload information of the given kind from all installed addons
--
-- @param kind  the payload kind, e.g. "plugins", "rules"
-- @return      the payload infos, e.g. {{name = "hello-world", version = "latest", dir = "~/.xmake/addons/hello-world/latest/plugins"}}
--
function addon.payloadinfos(kind)
    local payloadinfos = {}
    for name, addoninfo in pairs(addon.addons()) do
        if table.contains(addoninfo.payloads or {}, kind) then
            table.insert(payloadinfos, {
                name = name,
                version = addoninfo.version,
                dir = path.join(addon.installdir(), name, addoninfo.version, kind)})
        end
    end
    table.sort(payloadinfos, function (a, b) return a.name < b.name end)
    return payloadinfos
end

-- get the payload directories of the given addon directory, e.g. {"plugins", "rules"}
function addon.payloads_of(addondir)
    local payloads = {}
    for _, payloaddir in ipairs(addon.payloaddirs()) do
        if os.isdir(path.join(addondir, payloaddir)) then
            table.insert(payloads, payloaddir)
        end
    end
    return payloads
end

-- get the default on_install script of addon packages
--
-- we only install the payload directories of this addon, e.g. plugins, rules, toolchains, ...
--
function addon.installscript()
    return function (package)
        local installed = false
        for _, payloaddir in ipairs(addon.payloaddirs()) do
            if os.isdir(payloaddir) then
                os.cp(payloaddir, package:installdir())
                installed = true
            end
        end
        if not installed then
            os.raise("addon(%s): no payload directory found, e.g. plugins!", package:name())
        end
    end
end

-- save the given addons to the registry file
function addon._save(addons)
    addon._ADDONS = addons
    local registryfile = addon.registryfile()
    -- we need not create an empty registry file if no addons are installed
    if next(addons) == nil and not os.isfile(registryfile) then
        return
    end
    local ok, errors = io.save(registryfile, addons)
    if not ok then
        utils.warning(errors)
    end
end

-- register the given installed addon
--
-- @param name      the addon name
-- @param version   the addon version, e.g. "1.0.1", "latest"
-- @param opt       the options, e.g. {description = "..."}
--
function addon.register(name, version, opt)
    opt = opt or {}
    local dirname = addon.dirname(name)
    local addons = addon.addons()
    addons[dirname] = {version = version,
                       description = opt.description,
                       payloads = addon.payloads_of(path.join(addon.installdir(), dirname, version))}
    addon._save(addons)
end

-- unregister the given addon
function addon.unregister(name)
    local dirname = addon.dirname(name)
    local addons = addon.addons()
    if addons[dirname] then
        addons[dirname] = nil
        addon._save(addons)
    end
end

-- rescan the install directory and rebuild the registry
--
-- it's only used to repair the registry file, e.g. the user removed some addon directories manually
--
function addon.rescan()
    local oldaddons = addon.addons()
    local addons = {}
    for _, versiondir in ipairs(os.dirs(path.join(addon.installdir(), "*", "*"))) do
        local payloads = addon.payloads_of(versiondir)
        if #payloads > 0 then
            local dirname = path.filename(path.directory(versiondir))
            local version = path.filename(versiondir)
            -- we need to keep the description, we cannot get it from the installed payloads
            local oldaddoninfo = oldaddons[dirname]
            local description
            if oldaddoninfo and oldaddoninfo.version == version then
                description = oldaddoninfo.description
            end
            addons[dirname] = {version = version, description = description, payloads = payloads}
        end
    end
    addon._save(addons)
    return addons
end

-- clear all installed addons
function addon.clear()
    local installdir = addon.installdir()
    if os.isdir(installdir) then
        os.rmdir(installdir)
    end
    addon._ADDONS = {}
end

-- return module
return addon
