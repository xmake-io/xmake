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
-- @file        install_addons.lua
--

-- imports
import("core.package.addon")
import("core.project.addons")
import("private.action.addon.impl.xrepo", {alias = "xrepo_addon"})

-- the format version of the addons lock file
local LOCKVERSION = "1.0"

-- get the requires of the declared addons
--
-- @note we install the locked versions, but the declaration is authoritative, so we
-- resolve them again if the user has changed it or upgrades them
--
function _get_requires(addonsinfo, locked)
    local requires = {}
    for _, requirestr in ipairs(addonsinfo.addons) do
        local name = addons.requirename(requirestr)
        local lockinfo = locked and locked[name]
        if addons.locked_valid(requirestr, lockinfo) then
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
    local locked = addons.locked(projectdir) or {}
    -- @note we need to reload the registry, they have been installed by another process
    local installed = addon.addons({force = true})
    for _, requirestr in ipairs(addonsinfo.addons) do
        local name = addons.requirename(requirestr)
        local addoninfo = installed[addon.dirname(name)]
        if addoninfo then
            local oldversion = locked[name] and locked[name].version
            if oldversion and oldversion ~= addoninfo.version then
                cprint("${color.success}upgrade ${bright}%s${clear}: %s -> %s", name, oldversion, addoninfo.version)
            end
            -- we lock the repository too, so that the other users get it from the same source,
            -- @see xmake/modules/private/action/require/impl/lock_packages.lua
            lockinfo[name] = {version = addoninfo.version, repo = addoninfo.repo}
        end
    end
    lockinfo.__meta__ = {version = LOCKVERSION}

    -- @note we need to write it deterministically, the key order of a lua table is random,
    -- otherwise the lock file would change even if nothing changed,
    -- @see xmake/modules/private/action/require/impl/lock_packages.lua
    local content = string.serialize(lockinfo, {orderkeys = true})
    local tmpfile = os.tmpfile()
    io.writefile(tmpfile, content, {encoding = "binary"})

    -- and we only write it if the content is different, so we can keep the file time
    os.cp(tmpfile, addons.lockfile(projectdir), {copy_if_different = true})
    os.rm(tmpfile)
end

-- install the addons which the given project declares in its `xmake-addons.lua`
--
-- @note we are also called from a sub-process, the project cannot be loaded until
-- its addons are installed, @see core/project/project.lua
--
function main(projectdir, opt)
    opt = opt or {}
    projectdir = projectdir or os.projectdir()
    local addonsinfo = addons.load(projectdir)
    if not addonsinfo or #addonsinfo.addons == 0 then
        return
    end

    -- upgrade them? we need to resolve the declared versions again
    local locked = not opt.upgrade and addons.locked(projectdir) or nil

    -- install them with xrepo, it installs the packages in its own working directory,
    -- so we need not a project here

    -- this project declares its own repositories? we pass them to xrepo,
    -- they are only used by this installation, we do not register them globally
    local rcfile
    if #addonsinfo.repositories > 0 then
        rcfile = os.tmpfile() .. ".lua"
        local file = io.open(rcfile, "w")
        for _, repo in ipairs(addonsinfo.repositories) do
            file:print("add_repositories(%q)", repo)
        end
        file:close()
    end

    try
    {
        function ()
            xrepo_addon("install", _get_requires(addonsinfo, locked), {includes = rcfile})
        end,
        finally
        {
            -- @note try() swallows the errors if we do not re-raise them here
            function (ok, errors)
                if rcfile then
                    os.tryrm(rcfile)
                end
                if not ok then
                    raise(errors)
                end
            end
        }
    }

    -- and lock them, so that the other users get the same versions
    _lock_addons(projectdir, addonsinfo)
end
