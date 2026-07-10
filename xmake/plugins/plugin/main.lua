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
import("devel.git")
import("net.fasturl")
import("private.action.require.impl.environment")

-- get plugin urls
function _plugin_urls()
    local urls = option.get("plugins")
    if urls then
        local result = {}
        for _, url in ipairs(urls) do
            table.insert(result, git.asgiturl(url) or url)
        end
        urls = result
    else
        urls = {
        "https://github.com/xmake-io/xmake-plugins.git",
        "https://gitlab.com/tboox/xmake-plugins.git",
        "https://gitee.com/tboox/xmake-plugins.git"}
        urls = fasturl.add(urls)
        urls = fasturl.sort(urls)
    end
    return urls
end

-- get manifest path
function _manifest_path()
    return path.join(global.directory(), "plugins", "manifest.txt")
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

-- is the plugin package name? e.g. hello-world, myrepo@hello-world
--
-- the plugin url is the git url or local path, e.g.
-- https://github.com/xmake-io/xmake-plugins, git@github.com:xmake-io/xmake-plugins.git, /tmp/xmake-plugins
function _is_package_name(str)
    return not os.isdir(str) and not str:find("[/\\:]")
end

-- install the plugin package from repositories, e.g. xmake plugin --install hello-world
function _install_package(name, opt)
    opt = opt or {}
    local argv = {"lua", "private.xrepo", "install", "--kind=plugin"}
    if opt.force then
        table.insert(argv, "--force")
    end
    if option.get("yes") then
        table.insert(argv, "-y")
    end
    if option.get("verbose") then
        table.insert(argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(argv, "-D")
    end
    table.insert(argv, name)
    os.execv(os.programfile(), argv)
end

-- install plugins
function _install()

    -- install the plugin package from repositories?
    local name = option.get("plugins")
    if name and _is_package_name(name) then
        return _install_package(name)
    end

    -- enter environment
    environment.enter()

    try
    {
        function ()

            -- do install
            local urls = _plugin_urls()
            local tmpdir = os.tmpfile() .. ".dir"
            local plugindir = path.join(global.directory(), "plugins")
            local installed_url
            for _, url in ipairs(urls) do
                cprint("installing plugins from %s ..", url)
                git.clone(url, {verbose = option.get("verbose"), outputdir = tmpdir})
                installed_url = url
                break
            end
            for _, filepath in ipairs(os.files(path.join(tmpdir, "*", "xmake.lua"))) do
                local srcdir = path.directory(filepath)
                local name = path.filename(srcdir)
                local dstdir = path.join(plugindir, name)
                assert(not os.isdir(dstdir), "plugin(%s) already exists!", name)
                os.vcp(srcdir, dstdir)
                cprint("  ${yellow}->${clear} %s", name)
            end
            os.tryrm(tmpdir)

            -- save manifest
            if installed_url then
                local manifest = _load_manifest() or {}
                manifest.urls = manifest.urls or {}
                table.join2(manifest.urls, installed_url)
                _save_manifest(manifest)
            end
            cprint("${bright}all plugins have been installed in %s!", plugindir)
        end,
        catch
        {
            function (errors)
                raise(errors)
            end
        }
    }

    -- leave environment
    environment.leave()
end

-- update plugins
function _update()

    -- update the plugin package from repositories? e.g. xmake plugin --update hello-world
    local name = option.get("plugins")
    if name and _is_package_name(name) then
        return _install_package(name, {force = true})
    end

    -- enter environment
    environment.enter()

    try
    {
        function ()

            -- do update
            local manifest = _load_manifest()
            assert(manifest and manifest.urls, "3rd plugins not found!")
            local urls = manifest.urls
            local plugindir = path.join(global.directory(), "plugins")
            for _, url in ipairs(urls) do
                cprint("updating plugins from %s ..", url)
                local tmpdir = os.tmpfile() .. ".dir"
                git.clone(url, {verbose = option.get("verbose"), outputdir = tmpdir})
                for _, filepath in ipairs(os.files(path.join(tmpdir, "*", "xmake.lua"))) do
                    local srcdir = path.directory(filepath)
                    local name = path.filename(srcdir)
                    local dstdir = path.join(plugindir, name)
                    os.tryrm(dstdir)
                    os.vcp(srcdir, dstdir)
                    cprint("  ${yellow}->${clear} %s", name)
                end
                os.tryrm(tmpdir)
            end
            cprint("${bright}all plugins have been updated in %s!", plugindir)
        end,
        catch
        {
            function (errors)
                raise(errors)
            end
        }
    }

    -- leave environment
    environment.leave()
end

-- remove the given installed plugin
function _remove()
    local name = assert(option.get("plugins"), "please specify the plugin name to be removed!")
    -- avoid escaping the plugins directory, e.g. `xmake plugin --remove ../foo`
    assert(not name:find("..", 1, true) and not name:find("[/\\:]"), "invalid plugin name(%s)!", name)
    local plugindir = path.join(global.directory(), "plugins", name)
    assert(os.isdir(plugindir), "plugin(%s) not found!", name)
    os.rmdir(plugindir)
    cprint("${color.success}remove plugin(%s) ok!", name)
end

-- list all installed plugins
function _list()
    local plugindir = path.join(global.directory(), "plugins")
    cprint("plugins in ${bright}%s${clear}:", plugindir)
    for _, dir in ipairs(os.dirs(path.join(plugindir, "*"))) do
        if os.isfile(path.join(dir, "xmake.lua")) then
            local version, description
            local manifest_file = path.join(dir, "manifest.txt")
            if os.isfile(manifest_file) then
                local manifest = io.load(manifest_file)
                if manifest then
                    version = manifest.version
                    description = manifest.description
                end
            end
            cprint("  ${color.dump.string}%s${clear}%s: %s", path.filename(dir),
                version and ("-" .. version) or "",
                description or "")
        end
    end
end

-- clear all installed plugins
function _clear()
    local plugindir = path.join(global.directory(), "plugins")
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

