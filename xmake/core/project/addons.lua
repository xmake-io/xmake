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
-- @file        addons.lua
--

-- define module
local addons = addons or {}

-- load modules
local os    = require("base/os")
local io    = require("base/io")
local path  = require("base/path")
local table = require("base/table")
local semver = require("base/semver")
local addon  = require("package/addon")

-- the file which declares the addons of a project, e.g. <projectdir>/xmake-addons.lua
--
-- it's loaded before the project file, so that the addons are always installed when
-- we load the project, e.g. includes("@addon/esp32-devel/board")
--
-- e.g.
--   add_addons("esp32-devel 1.0.x")
--   add_addons("serial-tools", {optional = true})
--   add_repositories("myrepo git@github.com:me/myrepo.git")
--
function addons.filename()
    return "xmake-addons.lua"
end

function addons.file(projectdir)
    return path.join(projectdir or os.projectdir(), addons.filename())
end

-- the lock file of the declared addons, e.g. <projectdir>/xmake-addons.lock
--
-- @note it's independent of `xmake-requires.lock`, the addons are always locked,
-- they provide the build scripts and we should never change them silently
--
function addons.lockfile(projectdir)
    return path.join(projectdir or os.projectdir(), "xmake-addons.lock")
end

-- get the format version of the addons lock file
--
-- @see xmake/core/project/project.lua, project.requireslock_version()
--
function addons.lockfile_version()
    return "1.0"
end

-- get the apis of the addons file
--
-- @note it only declares which addons this project needs, the addon resources
-- are always referenced from the project file, e.g. add_rules("@addon/esp32-devel/app")
--
function addons.apis()
    return {
        values = {
            "add_addons"
            -- the repositories which provide them, e.g. add_repositories("myrepo git@github.com:me/myrepo.git")
        ,   "add_repositories"
        }
    }
end

-- the interpreter of the addons file
function addons._interpreter()
    local interp = addons._INTERPRETER
    if interp == nil then
        -- we need to load it lazily, the interpreter also depends on the addon module
        local interpreter = require("base/interpreter")
        interp = interpreter.new()
        interp:api_define(addons.apis())
        -- the sub-projects declare their addons in this file too,
        -- e.g. includes("sub") -> sub/xmake-addons.lua
        interp:includes_rootfilename_set(addons.filename())
        -- and we cannot reference the addons here, they have not been installed yet,
        -- e.g. includes("@addon/esp32-devel/board")
        interp:includes_references_set(false, "please move it to the project file(xmake.lua)!")
        addons._INTERPRETER = interp
    end
    return interp
end

-- load the declared addons of the given project directory
--
-- @return      the addons information and errors, it will be nil if this project declares nothing,
--              e.g. {addons = {"esp32-devel 1.0.x"}, addons_extra = {...}}
--
function addons.load(projectdir)
    local filepath = addons.file(projectdir)
    if not os.isfile(filepath) then
        return
    end

    -- enter the project directory, the include paths are relative to it,
    -- e.g. includes("sub")
    local oldir, errors = os.cd(path.directory(filepath))
    if not oldir then
        return nil, errors
    end

    local rootinfo
    local interp = addons._interpreter()
    local ok, errors = interp:load(filepath)
    if ok then
        rootinfo, errors = interp:make("root", true, true)
    end
    os.cd(oldir)
    if not rootinfo then
        return nil, errors
    end

    local addonsinfo = {addons = table.wrap(rootinfo:get("addons")),
                        addons_extra = rootinfo:extraconf("addons"),
                        repositories = table.wrap(rootinfo:get("repositories"))}

    -- check the declared addons
    local declared = {}
    for _, requirestr in ipairs(addonsinfo.addons) do

        -- this file is loaded before the addons are installed, so it cannot reference them
        if requirestr:startswith("@") then
            return nil, string.format("%s: cannot reference the addon resources(%s) here, please move it to the project file(xmake.lua)!",
                filepath, requirestr)
        end

        local name = addons.requirename(requirestr)
        if name == "addon" or name == "self" then
            return nil, string.format("%s: the addon name(%s) is reserved by xmake for the addon references, please rename it!",
                filepath, name)
        end
        if name == "." or name == ".." or name:find("[/\\:]") then
            return nil, string.format("%s: invalid addon name(%s)!", filepath, name)
        end

        -- we can only install one version of an addon for a project
        if declared[name] then
            return nil, string.format("%s: the addon(%s) is declared twice, e.g. `%s` and `%s`, please merge them!",
                filepath, name, declared[name], requirestr)
        end
        declared[name] = requirestr
    end
    return addonsinfo
end

-- split the given declaration into the name and the version range
--
-- @note the version range can contain spaces, so everything after the name belongs to it,
-- e.g. "esp32-devel 1.0.x", "esp32-devel >=1.0 <2.0", "esp32-devel master || >1.4",
-- @see xmake/modules/private/utils/package.lua
--
function addons.requirename(requirestr)
    local splitinfo = requirestr:split("%s+", {limit = 2})
    return splitinfo[1], splitinfo[2]
end

-- is the locked version still valid for the given declaration?
--
-- @note the declaration is authoritative, the lock only pins a version inside it,
-- so we need to resolve it again if the user has changed the declared version
--
function addons.locked_valid(requirestr, lockinfo)
    if not lockinfo or not lockinfo.version then
        return false
    end
    local _, range = addons.requirename(requirestr)
    if range then
        -- @note we can only compare the semantic versions, e.g. the local addons are always `latest`
        return semver.is_valid(lockinfo.version) and semver.satisfies(lockinfo.version, range)
    end
    return true
end

-- get the locked addons, e.g. {["esp32-devel"] = {version = "1.0.3"}}
function addons.locked(projectdir)
    local lockfile = addons.lockfile(projectdir)
    if os.isfile(lockfile) then
        local lockinfo = io.load(lockfile)
        if lockinfo then
            lockinfo.__meta__ = nil
            return lockinfo
        end
    end
end

-- are all the declared addons installed already?
--
-- @note we need to check it in-process for every command which loads the project,
-- so we only check the locked versions here, the installer will resolve them again
--
function addons.satisfied(addonsinfo, projectdir)
    local locked = addons.locked(projectdir)
    if not locked then
        return false
    end
    local installed = addon.addons()
    for _, requirestr in ipairs(addonsinfo.addons) do
        local name = addons.requirename(requirestr)
        local lockinfo = locked[name]
        if not addons.locked_valid(requirestr, lockinfo) then
            return false
        end
        local addoninfo = installed[addon.dirname(name)]
        if not addoninfo or addoninfo.version ~= lockinfo.version then
            return false
        end
    end
    return true
end

-- return module
return addons
