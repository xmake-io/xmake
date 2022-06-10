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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
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
    if not urls then
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

-- install plugins
function _install()

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
    elseif option.get("clear") then
        _clear()
    end
end

