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
import("core.package.repository")
import("devel.git")
import("private.action.require.impl.environment")

-- the version directory name for the addons installed from git urls or local directories
local LOCALVERSION = "latest"

-- validate an addon directory name
function _check_addon_name(name)
    assert(type(name) == "string" and name ~= "" and name ~= "." and not name:find("..", 1, true) and not name:find("[/\\:]"), "invalid addon name(%s)!", name)
    return name
end

-- get addon directory in ~/.xmake/addons
function _get_addondir(name, version)
    local addondir = addon.installdir()
    if name then
        addondir = path.join(addondir, addon.dirname(_check_addon_name(name)))
        if version then
            addondir = path.join(addondir, version)
        end
    end
    return addondir
end

-- get local and global repositories, with local taking precedence
function _repositories()
    return table.join(repository.repositories({global = false}), repository.repositories({global = true}))
end

-- install an addon from the given repository or the first repository containing it
function _install_from_repo(name, reponame)

    -- check addon name
    _check_addon_name(name)

    -- do install
    local installname = name
    if reponame then
        installname = reponame .. "@" .. name
    end
    local argv = {"lua", "private.xrepo", "install", "--addon"}
    -- we need to pass the common options to the sub-process, e.g. -y, -v, -D
    if option.get("yes") then
        table.insert(argv, "-y")
    end
    if option.get("verbose") then
        table.insert(argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(argv, "-D")
    end
    table.insert(argv, installname)
    os.execv(os.programfile(), argv)
end

-- install a single addon from a source directory (as the given name, default to the directory name)
function _install_from_local(dir, name)
    assert(os.isdir(dir), "addon path(%s) not found!", dir)
    assert(#addon.payloads_of(dir) > 0, "addon path(%s): no payload directory found, e.g. ${bright}plugins${clear}!", dir)
    name = name or path.filename(path.absolute(dir))
    local dstdir = _get_addondir(name, LOCALVERSION)
    assert(not os.isdir(dstdir), "addon(%s) already exists!", name)
    os.vcp(dir, dstdir)
    addon.register(name, LOCALVERSION)
    cprint("${color.success}install ${bright}%s${clear} ok!", name)
end

-- install a single addon from a git url or github shortcut, e.g. https://github.com/xmake-addons/serial-monitor
function _install_from_git(url)
    local branch
    if url:startswith("github:") then
        local i = url:find("#", 1, true)
        if i then
            branch = url:sub(i + 1)
            url = url:sub(1, i - 1)
        end
        url = git.asgiturl(url)
    end
    local name = (path.filename(url):gsub("%.git$", ""))
    local tmpdir = os.tmpfile() .. ".dir"
    git.clone(url, {verbose = option.get("verbose"), branch = branch, outputdir = tmpdir})
    os.tryrm(path.join(tmpdir, ".git"))
    _install_from_local(tmpdir, name)
    os.tryrm(tmpdir)
end

-- install a single addon
function _install_one(name)
    -- parse repo@addon format
    local i = name:find("@", 1, true)
    if i and not name:find("[/\\:]") then
        local reponame = name:sub(1, i - 1)
        local addonname = name:sub(i + 1)
        _install_from_repo(addonname, reponame)
        return
    end

    -- github shortcut: github:user/repo or github:user/repo#branch
    if name:startswith("github:") then
        _install_from_git(name)
        return
    end

    -- git url or local path
    if git.asgiturl(name) then
        _install_from_git(name)
        return
    elseif os.isdir(name) then
        _install_from_local(name)
        return
    end

    -- plain name: try to find it in repositories
    _install_from_repo(name)
end

-- install addons
function _install()
    local names = assert(option.get("addons"), "please specify the addons to be installed!")
    environment.enter()
    for _, name in ipairs(names) do
        _install_one(name)
    end
    environment.leave()
end

-- remove the given installed addon
function _remove()
    local names = assert(option.get("addons"), "please specify the addon name to be removed!")
    assert(#names == 1, "please specify only one addon name to be removed!")
    local name = names[1]
    local dir = _get_addondir(name)
    assert(os.isdir(dir), "addon(%s) not found!", name)
    os.rmdir(dir)
    addon.unregister(name)
    cprint("${color.success}remove ${bright}%s${clear} ok!", name)
end

-- get the description of an addon from its package description file
function _addon_description(dir)
    local filepath = path.join(dir, "xmake.lua")
    if os.isfile(filepath) then
        local content = io.readfile(filepath)
        if content then
            return content:match("set_description%s*%(\"(.-)\"%)")
        end
    end
end

-- collect the installed addons from the addons registry
--
-- we always rescan the install directory here to repair the registry,
-- e.g. the user may remove some addon directories manually
--
function _collect_installed_addons()
    local entries = {}
    for name, addoninfo in pairs(addon.rescan()) do
        table.insert(entries, {name = name, version = addoninfo.version,
                               description = addoninfo.description, payloads = addoninfo.payloads})
    end
    table.sort(entries, function (a, b) return a.name < b.name end)
    return entries
end

-- collect the addons in the given repository, they follow the packages layout (addons/<first-letter>/<name>)
function _collect_repo_addons(root, seen)
    local entries = {}
    for _, dir in ipairs(os.dirs(path.join(root, "*", "*"))) do
        local name = path.filename(dir)
        if os.isfile(path.join(dir, "xmake.lua")) and not seen[name] then
            seen[name] = true
            table.insert(entries, {name = name, description = _addon_description(dir)})
        end
    end
    return entries
end

-- print an addon entry with its description aligned on the right
function _print_addon(name, description, width, note)
    local suffix = description or ""
    if note then
        suffix = suffix ~= "" and (suffix .. " " .. note) or note
    end
    if suffix ~= "" then
        local padding = math.max(width - #name, 1)
        cprint("  ${color.dump.string}%s${clear}%s%s", name, (" "):rep(padding), suffix)
    else
        cprint("  ${color.dump.string}%s${clear}", name)
    end
end

-- list all addons
function _list()
    local seen = {}
    local installed = _collect_installed_addons()
    for _, entry in ipairs(installed) do
        seen[entry.name] = true
    end
    local avail = {}
    for _, repo in ipairs(_repositories()) do
        table.join2(avail, _collect_repo_addons(path.join(repo:directory(), "addons"), seen))
    end

    -- compute the alignment width from all addon names
    local width = 0
    for _, entries in ipairs({installed, avail}) do
        for _, entry in ipairs(entries) do
            width = math.max(width, #entry.name + 4)
        end
    end

    -- installed addons
    cprint("${bright}the installed addons:${clear}")
    if #installed > 0 then
        for _, entry in ipairs(installed) do
            local note = string.format("(%s, %s)", entry.version, table.concat(entry.payloads, ", "))
            _print_addon(entry.name, entry.description, width, note)
        end
    else
        print("  (none)")
    end

    -- addons available in repositories (not yet installed)
    cprint("${bright}available in configured repositories:${clear}")
    if #avail > 0 then
        for _, entry in ipairs(avail) do
            local note = string.format("(run xmake addon --install %s to install)", entry.name)
            _print_addon(entry.name, entry.description, width, note)
        end
    else
        print("  (none)")
    end
end

-- clear all installed addons
function _clear()
    addon.clear()
    cprint("${color.success}clear all installed addons ok!")
end

function main()
    if option.get("install") then
        _install()
    elseif option.get("remove") then
        _remove()
    elseif option.get("list") then
        _list()
    elseif option.get("clear") then
        _clear()
    end
end
