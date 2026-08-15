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
import("core.base.global")
import("core.package.repository")
import("devel.git")
import("private.action.require.impl.environment")
import("private.action.require.impl.install_packages")

-- validate a plugin directory name
function _check_plugin_name(name)
    assert(type(name) == "string" and name ~= "" and name ~= "." and not name:find("..", 1, true) and not name:find("[/\\:]"), "invalid plugin name(%s)!", name)
    return name
end

-- get plugin directory in ~/.xmake/plugins
function _get_plugindir(name)
    local plugindir = path.join(global.directory(), "plugins")
    return name and path.join(plugindir, _check_plugin_name(name)) or plugindir
end

-- get local and global repositories, with local taking precedence
function _repositories()
    return table.join(repository.repositories({global = false}), repository.repositories({global = true}))
end

-- install a plugin from the given repository or the first repository containing it
function _install_plugins_from_repo(name, reponame)

    -- check plugin name
    _check_plugin_name(name)

    -- do install
    local installname = name
    if reponame then
        installname = reponame .. "@" .. name
    end
    local argv = {"lua", "private.xrepo", "install", "--plugin"}
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

-- install a single plugin from a source directory (as the given name, default to the directory name)
function _install_from_local(dir, name)
    assert(os.isdir(dir) and os.isfile(path.join(dir, "xmake.lua")), "plugin path(%s): ${bright}xmake.lua${clear} not found!", dir)
    name = name or path.filename(path.absolute(dir))
    local dstdir = _get_plugindir(name)
    assert(not os.isdir(dstdir), "plugin(%s) already exists!", name)
    os.vcp(dir, dstdir)
    cprint("${color.success}install ${bright}%s${clear} ok!", name)
end

-- install a single plugin from a git url or github shortcut, e.g. https://github.com/xmake-io/hello-world
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

-- install a single plugin
function _install_one(name)
    -- parse repo@plugin format
    local i = name:find("@", 1, true)
    if i and not name:find("[/\\:]") then
        local reponame = name:sub(1, i - 1)
        local pluginname = name:sub(i + 1)
        _install_plugins_from_repo(pluginname, reponame)
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
    _install_plugins_from_repo(name)
end

-- install plugins
function _install()
    local names = assert(option.get("plugins"), "please specify the plugins to be installed!")
    environment.enter()
    for _, name in ipairs(names) do
        _install_one(name)
    end
    environment.leave()
end

-- remove the given installed plugin
function _remove()
    local names = assert(option.get("plugins"), "please specify the plugin name to be removed!")
    assert(#names == 1, "please specify only one plugin name to be removed!")
    local name = names[1]
    local dir = _get_plugindir(name)
    assert(os.isdir(dir), "plugin(%s) not found!", name)
    os.rmdir(dir)
    cprint("${color.success}remove ${bright}%s${clear} ok!", name)
end

-- get the description of a plugin from its xmake.lua menu
function _plugin_description(dir)
    local filepath = path.join(dir, "xmake.lua")
    if os.isfile(filepath) then
        local content = io.readfile(filepath)
        if content then
            -- parse description from task or package scope
            return content:match("description%s*=%s*\"(.-)\"") or content:match("set_description%s*%(\"(.-)\"%)")
        end
    end
end

-- collect plugins (each subdirectory containing xmake.lua) under the given root
--
-- built-in/installed plugins are flat (<root>/<name>), while plugins in a
-- repository follow the packages layout (<root>/<first-letter>/<name>)
function _collect_plugins(root, seen, nested)
    local entries = {}
    local pattern = nested and path.join(root, "*", "*") or path.join(root, "*")
    for _, dir in ipairs(os.dirs(pattern) or {}) do
        local name = path.filename(dir)
        if os.isfile(path.join(dir, "xmake.lua")) and (not seen or not seen[name]) then
            if seen then
                seen[name] = true
            end
            table.insert(entries, {name = name, description = _plugin_description(dir)})
        end
    end
    return entries
end

-- print a plugin entry with its description aligned on the right
function _print_plugin(name, description, width, note)
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

-- list all plugins
function _list()
    local seen = {}

    -- collect plugins from every source
    local builtin = _collect_plugins(path.join(os.programdir(), "plugins"), seen)
    local plugindir = _get_plugindir()
    local installed = _collect_plugins(plugindir, seen)
    local avail = {}
    for _, repo in ipairs(_repositories()) do
        table.join2(avail, _collect_plugins(path.join(repo:directory(), "plugins"), seen, true))
    end

    -- compute the alignment width from all plugin names
    local width = 0
    for _, entries in ipairs({builtin, installed, avail}) do
        for _, entry in ipairs(entries) do
            width = math.max(width, #entry.name + 4)
        end
    end

    -- built-in plugins
    cprint("${bright}the built-in plugins:${clear}")
    if #builtin > 0 then
        for _, entry in ipairs(builtin) do
            _print_plugin(entry.name, entry.description, width)
        end
    else
        print("  (none)")
    end

    -- installed plugins
    cprint("${bright}the installed plugins:${clear}")
    if #installed > 0 then
        for _, entry in ipairs(installed) do
            _print_plugin(entry.name, entry.description, width)
        end
    else
        print("  (none)")
    end

    -- plugins available in repositories (not yet installed)
    cprint("${bright}available in configured repositories:${clear}")
    if #avail > 0 then
        for _, entry in ipairs(avail) do
            local note = string.format("(run xmake plugin --install %s to install)", entry.name)
            _print_plugin(entry.name, entry.description, width, note)
        end
    else
        print("  (none)")
    end
end

-- clear all installed plugins
function _clear()
    local plugindir = _get_plugindir()
    if os.isdir(plugindir) then
        os.rmdir(plugindir)
    end
    cprint("${color.success}clear all installed plugins ok!")
end

function main()
    cprint("${bright color.warning}${text.warning}: ${color.warning}`xmake plugin` is deprecated, please use `xmake addon` instead!")
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
