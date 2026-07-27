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
import("net.fasturl")
import("private.action.require.impl.environment")

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

-- get plugin urls for batch install
function _plugin_urls()
    local urls = {
    "https://github.com/xmake-io/xmake-plugins.git",
    "https://gitlab.com/tboox/xmake-plugins.git",
    "https://gitee.com/tboox/xmake-plugins.git"}
    fasturl.add(urls)
    return fasturl.sort(urls)
end

-- run a function with a temporary directory that is removed on success or failure
function _with_tmpdir(fn)
    local tmpdir = os.tmpfile() .. ".dir"
    return try
    {
        function ()
            return fn(tmpdir)
        end,
        catch
        {
            function (errors)
                os.tryrm(tmpdir)
                raise(errors)
            end
        },
        finally
        {
            function ()
                os.tryrm(tmpdir)
            end
        }
    }
end

function _manifest_path()
    return path.join(_get_plugindir(), "manifest.txt")
end

-- load manifest
function _load_manifest()
    local manifest_path = _manifest_path()
    if os.isfile(manifest_path) then
        return io.load(manifest_path)
    end
end

-- save manifest
function _save_manifest(manifest)
    io.save(_manifest_path(), manifest)
end

-- find a plugin directory in the given repository directory
function _find_plugin_in_repo(repodir, name)
    local dir = path.join(repodir, "plugins", name)
    if os.isdir(dir) and os.isfile(path.join(dir, "xmake.lua")) then
        return dir
    end
end

-- install a plugin from the given repository or the first repository containing it
function _install_plugins_from_repo(name, reponame)
    _check_plugin_name(name)
    for _, repo in ipairs(_repositories()) do
        if not reponame or repo:name() == reponame then
            local srcdir = _find_plugin_in_repo(repo:directory(), name)
            if srcdir then
                local dstdir = _get_plugindir(name)
                assert(not os.isdir(dstdir), "plugin(%s) already exists!", name)
                os.vcp(srcdir, dstdir)
                cprint("${color.success}install ${bright}%s${clear} from repository ${bright}%s${clear} ok!", name, repo:name())
                return
            end
        end
    end
    if reponame then
        raise("plugin(%s): not found in repository %s!", name, reponame)
    end
    raise("plugin(%s): not found in any repository! try ${bright}xrepo update-repo${clear} first.", name)
end

-- install a plugin from a local directory
function _install_from_local(dir)
    assert(os.isdir(dir) and os.isfile(path.join(dir, "xmake.lua")), "plugin path(%s): ${bright}xmake.lua${clear} not found!", dir)
    local name = path.filename(path.absolute(dir))
    local dstdir = _get_plugindir(name)
    assert(not os.isdir(dstdir), "plugin(%s) already exists!", name)
    os.vcp(dir, dstdir)
    cprint("${color.success}install ${bright}%s${clear} from ${bright}%s${clear} ok!", name, dir)
end

-- install a plugin from a git url or github shortcut
function _install_from_git(url)
    local branch
    if url:startswith("github:") then
        url = url:sub(8)
        local i = url:find("#", 1, true)
        if i then
            branch = url:sub(i + 1)
            url = url:sub(1, i - 1)
        end
        url = "https://github.com/" .. url .. ".git"
    end
    _with_tmpdir(function (tmpdir)
        local clone_opt = {verbose = option.get("verbose"), outputdir = tmpdir}
        if branch then
            clone_opt.branch = branch
        end
        git.clone(git.asgiturl(url) or url, clone_opt)
        local found = false
        local function install(srcdir, name)
            local dstdir = _get_plugindir(name)
            assert(not os.isdir(dstdir), "plugin(%s) already exists!", name)
            os.vcp(srcdir, dstdir)
            cprint("  ${color.success}-> ${bright}%s${clear}", name)
            found = true
        end
        if os.isfile(path.join(tmpdir, "xmake.lua")) then
            install(tmpdir, path.basename(path.filename(url)))
        else
            for _, filepath in ipairs(os.files(path.join(tmpdir, "*", "xmake.lua"))) do
                local srcdir = path.directory(filepath)
                install(srcdir, path.filename(srcdir))
            end
        end
        if not found then
            raise("no plugin found in %s", url)
        end
    end)
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
    if name:startswith("file://") or git.asgiturl(name) then
        _install_from_git(name)
        return
    elseif os.isdir(name) then
        _install_from_local(name)
        return
    elseif name:find("[/\\:]") then
        _install_from_git(name)
        return
    end

    -- plain name: try to find it in repositories
    _install_plugins_from_repo(name)
end

-- install plugins
function _install()

    -- enter environment
    environment.enter()

    local errors
    try
    {
        function ()

            -- install requested plugins
            local names = option.get("plugins")
            if names then
                for _, name in ipairs(names) do
                    _install_one(name)
                end
                return
            end

            -- do batch install from plugin collection urls
            local urls = _plugin_urls()
            local plugindir = _get_plugindir()
            local installed_url
            _with_tmpdir(function (tmpdir)
                for _, url in ipairs(urls) do
                    cprint("installing plugins from ${bright}%s${clear} ..", url)
                    local ok = try
                    {
                        function ()
                            git.clone(url, {verbose = option.get("verbose"), outputdir = tmpdir})
                            return true
                        end
                    }
                    if ok then
                        installed_url = url
                        break
                    end
                    os.tryrm(tmpdir)
                end
                assert(installed_url, "failed to install plugins from all urls!")
                for _, filepath in ipairs(os.files(path.join(tmpdir, "*", "xmake.lua"))) do
                    local srcdir = path.directory(filepath)
                    local name = path.filename(srcdir)
                    local dstdir = _get_plugindir(name)
                    assert(not os.isdir(dstdir), "plugin(%s) already exists!", name)
                    os.vcp(srcdir, dstdir)
                    cprint("  ${color.success}-> ${bright}%s${clear}", name)
                end
            end)
            local manifest = _load_manifest() or {}
            manifest.urls = manifest.urls or {}
            table.join2(manifest.urls, installed_url)
            _save_manifest(manifest)
            cprint("${color.success}all plugins have been installed in ${bright}%s${clear}!", plugindir)
        end,
        catch
        {
            function (_errors)
                errors = _errors
            end
        }
    }

    -- leave environment
    environment.leave()
    if errors then
        raise(errors)
    end
end

-- update plugins
function _update()

    -- enter environment
    environment.enter()

    local errors
    try
    {
        function ()

            -- do update
            local manifest = _load_manifest()
            assert(manifest and manifest.urls, "3rd plugins not found!")
            local urls = manifest.urls
            local plugindir = _get_plugindir()
            for _, url in ipairs(urls) do
                cprint("updating plugins from ${bright}%s${clear} ..", url)
                _with_tmpdir(function (tmpdir)
                    git.clone(url, {verbose = option.get("verbose"), outputdir = tmpdir})
                    for _, filepath in ipairs(os.files(path.join(tmpdir, "*", "xmake.lua"))) do
                        local srcdir = path.directory(filepath)
                        local name = path.filename(srcdir)
                        local dstdir = _get_plugindir(name)
                        os.tryrm(dstdir)
                        os.vcp(srcdir, dstdir)
                        cprint("  ${color.success}-> ${bright}%s${clear}", name)
                    end
                end)
            end
            cprint("${color.success}all plugins have been updated in ${bright}%s${clear}!", plugindir)
        end,
        catch
        {
            function (_errors)
                errors = _errors
            end
        }
    }

    -- leave environment
    environment.leave()
    if errors then
        raise(errors)
    end
end

-- remove the given installed plugin
function _remove()
    local names = assert(option.get("plugins"), "please specify the plugin name to be removed!")
    assert(#names == 1, "please specify only one plugin name to be removed!")
    local name = _check_plugin_name(names[1])
    local dir = _get_plugindir(name)
    assert(os.isdir(dir), "plugin(%s) not found!", name)
    os.rmdir(dir)
    cprint("${color.success}remove ${bright}%s${clear} ok!", name)
end

-- list all plugins
function _list()
    local seen = {}

    -- installed plugins
    local plugindir = _get_plugindir()
    cprint("${bright}the installed plugins:${clear}")
    local found = false
    for _, dir in ipairs(os.dirs(path.join(plugindir, "*")) or {}) do
        if os.isfile(path.join(dir, "xmake.lua")) then
            local name = path.filename(dir)
            seen[name] = true
            found = true
            cprint("  ${bright}%s${clear}", name)
        end
    end
    if not found then
        print("  (none)")
    end

    -- plugins available in repositories (not yet installed)
    cprint("${bright}in xmake-repo:${clear}")
    local avail = false
    local repos = _repositories()
    for _, repo in ipairs(repos) do
        local rplugindir = path.join(repo:directory(), "plugins")
        if os.isdir(rplugindir) then
            for _, subdir in ipairs(os.dirs(path.join(rplugindir, "*")) or {}) do
                local name = path.filename(subdir)
                if os.isfile(path.join(subdir, "xmake.lua")) and not seen[name] then
                    seen[name] = true
                    avail = true
                    cprint("    - ${bright}%s${clear} ${dim}(run ${bright}xmake plugin --install %s${clear}${dim} to install)${clear}", name, name)
                end
            end
        end
    end
    if not avail then
        print("    (none)")
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
    if option.get("install") then
        _install()
    elseif option.get("update") then
        _update()
    elseif option.get("remove") then
        _remove()
    elseif option.get("list") then
        _list()
    elseif option.get("clear") then
        _clear()
    end
end
