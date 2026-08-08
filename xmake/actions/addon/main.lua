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
import("devel.git")
import("private.action.require.impl.environment")
import("private.action.require.impl.search_packages")

-- the version directory name for the addons installed from git urls or local directories
local LOCALVERSION = "latest"

-- the maximum number of the available addons shown by `--list`
local LISTLIMIT = 10

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

-- run the given xrepo action for the addons, e.g. install, remove, search
function _xrepo(action, names)
    local argv = {"lua", "private.xrepo", action, "--addon"}
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
    table.join2(argv, names)
    os.execv(os.programfile(), argv)
end

-- install an addon from the given repository or the first repository containing it
function _install_from_repo(name, reponame)
    _check_addon_name(name)
    _xrepo("install", {reponame and (reponame .. "@" .. name) or name})
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

-- remove the given installed addons
function _remove()
    local names = assert(option.get("addons"), "please specify the addon name to be removed!")
    _xrepo("remove", names)
end

-- search the addons from the repositories
function _search()
    local patterns = assert(option.get("addons"), "please specify the addon name pattern to be searched!")
    _xrepo("search", patterns)
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

-- print an addon entry, e.g. -> serial-monitor v1.0.1: monitor the serial port output (in xmake-repo)
function _print_addon(entry, suffix)
    local title = entry.name
    if entry.version then
        title = title .. " " .. entry.version
    end
    local description = entry.description and (": " .. entry.description) or ""
    cprint("  ${color.dump.reference}->${clear} ${color.dump.string}%s${clear}%s%s", title, description, suffix or "")
end

-- get the addons in the repositories, we reuse the packages search here
function _collect_repo_addons(exclude)
    local entries = {}
    for _, results in pairs(search_packages({"*"}, {kind = "addon", description = false})) do
        for _, result in ipairs(results) do
            if not exclude[result.name] then
                table.insert(entries, result)
            end
        end
    end
    table.sort(entries, function (a, b) return a.name < b.name end)
    return entries
end

-- list all addons
function _list()

    -- show the installed addons
    local installed = _collect_installed_addons()
    local exclude = {}
    cprint("${bright}the installed addons:${clear}")
    if #installed > 0 then
        for _, entry in ipairs(installed) do
            exclude[entry.name] = true
            _print_addon(entry, string.format(" ${dim}(%s)${clear}", table.concat(entry.payloads, ", ")))
        end
    else
        print("  (none)")
    end

    -- show the addons in the repositories, we only show the first ones if there are too many
    local avail = _collect_repo_addons(exclude)
    cprint("${bright}the available addons:${clear} ${dim}(run `xmake addon --install <name>` to install," ..
           " `--search <pattern>` to search)${clear}")
    if #avail > 0 then
        for idx, entry in ipairs(avail) do
            if idx > LISTLIMIT then
                cprint("  ${dim}... and %d more${clear}", #avail - LISTLIMIT)
                break
            end
            _print_addon(entry, entry.reponame and string.format(" ${dim}(in %s)${clear}", entry.reponame) or nil)
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
    elseif option.get("search") then
        _search()
    elseif option.get("clear") then
        _clear()
    end
end
