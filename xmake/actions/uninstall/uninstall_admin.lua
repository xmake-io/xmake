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
-- @file        uninstall_admin.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("uninstall")

function main(targetname, installdir, bindir, libdir, includedir)
    local verbose = option.get("verbose")
    if installdir and #installdir == 0 then
        installdir = nil
    end
    if bindir and #bindir == 0 then
        bindir = nil
    end
    if libdir and #libdir == 0 then
        libdir = nil
    end
    if includedir and #includedir == 0 then
        includedir = nil
    end

    os.cd(project.directory())
    config.load()
    platform.load(config.plat())

    -- save the current option and push a new option context
    option.save()
    option.set("verbose", verbose)
    if installdir then
        option.set("installdir", installdir)
    end
    if bindir then
        option.set("bindir", bindir)
    end
    if libdir then
        option.set("libdir", libdir)
    end
    if includedir then
        option.set("includedir", includedir)
    end
    -- uninstall target
    uninstall(targetname ~= "__all" and targetname or nil)
    option.restore()
end
end
