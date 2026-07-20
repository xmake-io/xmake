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
-- @file        plugins.lua
--

-- imports
import("core.base.global")

-- get the plugin directory of the given plugin package in the global plugins directory
function plugindir(name)
    return path.join(global.directory(), "plugins", name)
end

-- register the given plugin package to the global plugins directory,
-- then we can run it directly. e.g. `xmake plugin-name`
function register(package)
    local installdir = package:installdir()
    assert(os.isfile(path.join(installdir, "xmake.lua")),
        "plugin(%s): xmake.lua not found in the installed files, it should be installed with `os.cp(\"*\", package:installdir())`!", package:name())
    local dir = plugindir(package:name())
    -- we copy it to the temporary directory first and then swap it,
    -- so the previous plugin will not be lost if copying fails. e.g. disk full
    --
    -- we cannot use the sibling directory, e.g. `plugins/<name>.tmp`,
    -- because the task loader will load all plugins from `plugins/*/xmake.lua`
    local tmpdir = path.join(path.directory(dir), ".tmp", package:name())
    os.tryrm(tmpdir)
    os.cp(installdir, tmpdir)
    -- remove the install logs, they do not belong to the plugin,
    -- but we keep manifest.txt to show the plugin version and description. e.g. `xmake plugin --list`
    os.tryrm(path.join(tmpdir, "logs"))
    -- replace the previous plugin only after the new one is fully ready,
    -- and we backup the previous plugin, it can be restored by `rollback()` if the installation fails later. e.g. test failure
    local bakdir = tmpdir .. ".bak"
    os.tryrm(bakdir)
    if os.isdir(dir) then
        os.mv(dir, bakdir)
    end
    os.mv(tmpdir, dir)
    vprint("register plugin(%s) to %s", package:name(), dir)
end

-- confirm the registered plugin and discard the previous backup
function confirm(name)
    os.tryrm(path.join(path.directory(plugindir(name)), ".tmp", name .. ".bak"))
end

-- rollback the registered plugin and restore the previous backup if the installation fails
function rollback(name)
    local dir = plugindir(name)
    local bakdir = path.join(path.directory(dir), ".tmp", name .. ".bak")
    if os.isdir(bakdir) then
        os.tryrm(dir)
        os.mv(bakdir, dir)
        vprint("restore the previous plugin(%s) to %s", name, dir)
    end
end

-- unregister the given plugin from the global plugins directory
function unregister(name)
    local dir = plugindir(name)
    if os.isdir(dir) then
        os.tryrm(dir)
        vprint("unregister plugin(%s) from %s", name, dir)
    end
end
