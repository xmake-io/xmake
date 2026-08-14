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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.package.addon")
import("core.project.addons")

-- the format version of the addons lock file
local LOCKVERSION = "1.0"

-- get the requires of the declared addons
--
-- @note we always install the locked versions, the declared versions are only used
-- to resolve them when there is no lock yet, @see _lock_addons
--
function _get_requires(addonsinfo, locked)
    local requires = {}
    for _, requirestr in ipairs(addonsinfo.addons) do
        local name = requirestr:split("%s")[1]
        local lockinfo = locked and locked[name]
        if lockinfo and lockinfo.version then
            requirestr = name .. " " .. lockinfo.version
        end
        table.insert(requires, requirestr)
    end
    return requires
end

-- lock the installed addons, so that we always get the same ones
--
-- @note we get the installed versions from the addons registry, they are
-- registered when installing them, @see core/package/addon.lua
--
function _lock_addons(projectdir, addonsinfo)
    local lockinfo = {}
    -- @note we need to reload the registry, they have been installed by another process
    local installed = addon.addons({force = true})
    for _, requirestr in ipairs(addonsinfo.addons) do
        local name = requirestr:split("%s")[1]
        local addoninfo = installed[addon.dirname(name)]
        if addoninfo then
            lockinfo[name] = {version = addoninfo.version}
        end
    end
    lockinfo.__meta__ = {version = LOCKVERSION}
    io.save(addons.lockfile(projectdir), lockinfo, {orderkeys = true})
end

-- install the addons which the given project declares in its `xmake-addons.lua`
--
-- @note we are called from a sub-process, the project cannot be loaded until its
-- addons are installed, @see core/project/project.lua
--
function main(projectdir)
    projectdir = projectdir or os.projectdir()
    local addonsinfo = addons.load(projectdir)
    if not addonsinfo or #addonsinfo.addons == 0 then
        return
    end

    -- install them with xrepo, it installs the packages in its own working directory,
    -- so we need not a project here
    local argv = {"lua", "private.xrepo", "install", "--addon"}
    for _, name in ipairs({"yes", "verbose", "diagnosis"}) do
        if option.get(name) then
            table.insert(argv, "--" .. name)
        end
    end
    table.join2(argv, _get_requires(addonsinfo, addons.locked(projectdir)))
    os.execv(os.programfile(), argv)

    -- and lock them, so that the other users get the same versions
    _lock_addons(projectdir, addonsinfo)
end
