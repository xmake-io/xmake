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
local sandbox_core_package_addon = sandbox_core_package_addon or {}

-- load modules
local addon = require("package/addon")
local raise = require("sandbox/modules/raise")

-- inherit some builtin interfaces
sandbox_core_package_addon.installdir        = addon.installdir
sandbox_core_package_addon.workdir           = addon.workdir
sandbox_core_package_addon.dirname           = addon.dirname
sandbox_core_package_addon.owner             = addon.owner
sandbox_core_package_addon.payloadinfos      = addon.payloadinfos
sandbox_core_package_addon.payloads_of       = addon.payloads_of
sandbox_core_package_addon.payloadroot       = addon.payloadroot
sandbox_core_package_addon.addons            = addon.addons
sandbox_core_package_addon.versions          = addon.versions
sandbox_core_package_addon.unregister        = addon.unregister

-- get the manifest of the given addon directory, e.g. <sourcedir>/addon.lua
--
-- @param sourcedir the addon source or install directory
-- @return          the manifest, it will be nil if this addon does not describe itself
--
function sandbox_core_package_addon.manifest(sourcedir)
    local manifest, errors = addon.manifest(sourcedir)
    if errors then
        raise(errors)
    end
    return manifest
end

-- resolve the given addon reference, e.g. `@addon/<addon>/<name>`, `@self/<name>`
--
-- @param reference the addon reference
-- @param sep       the separator, e.g. "/", "."
-- @param kind      the payload kind, e.g. "rules", "modules"
-- @param opt       the options, e.g. {scriptdir = "..."}
--
-- @return          the reference information, e.g. {dir = "...", name = "flash", addon = "esp32"}
--
function sandbox_core_package_addon.resolve_reference(reference, sep, kind, opt)
    local referenceinfo, errors = addon.resolve_reference(reference, sep, kind, opt)
    if errors then
        raise(errors)
    end
    return referenceinfo
end

-- register the given installed addon
--
-- @param name      the addon name
-- @param version   the addon version, e.g. "1.0.1", "latest"
-- @param opt       the options, e.g. {description = "...", deps = {"foo"}}
--
function sandbox_core_package_addon.register(name, version, opt)
    local ok, errors = addon.register(name, version, opt)
    if not ok then
        raise(errors)
    end
end

-- remove the given installed addon
--
-- @param name      the addon name
-- @param opt       the options, e.g. {force = true}
--
function sandbox_core_package_addon.remove(name, opt)
    local ok, errors = addon.remove(name, opt)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_package_addon
