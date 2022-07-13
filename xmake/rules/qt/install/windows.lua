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
-- @file        windows.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.tool.toolchain")
import("lib.detect.find_path")

-- install application package for windows
function main(target, opt)

    local targetfile = target:targetfile()
    local installfile = path.join(target:installdir(), "bin", path.filename(targetfile))

    -- get qt sdk
    local qt = target:data("qt")

    -- get windeployqt
    local windeployqt = path.join(qt.bindir, "windeployqt.exe")
    assert(os.isexec(windeployqt), "windeployqt.exe not found!")

    -- find qml directory
    local qmldir = target:values("qt.deploy.qmldir")
    if not qmldir then
        for _, sourcebatch in pairs(target:sourcebatches()) do
            if sourcebatch.rulename == "qt.qrc" then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    qmldir = find_path("*.qml", path.directory(sourcefile))
                    if qmldir then
                        break
                    end
                end
            end
        end
    else
        qmldir = path.join(target:scriptdir(), qmldir)
    end

    -- find msvc to set VCINSTALLDIR env
    local envs = nil
    local msvc = toolchain.load("msvc", {plat = target:plat(), arch = target:arch()})
    if msvc then
        local vcvars = msvc:config("vcvars")
        if vcvars and vcvars.VCInstallDir then
            envs = {VCINSTALLDIR = vcvars.VCInstallDir}
        end
    end

    local argv = {"--force"}
    if option.get("diagnosis") then
        table.insert(argv, "--verbose=2")
    elseif option.get("verbose") then
        table.insert(argv, "--verbose=1")
    else
        table.insert(argv, "--verbose=0")
    end

    if is_mode("debug") then
        table.insert(argv, "--debug")
    else
        table.insert(argv, "--release")
    end

    if qmldir then
        table.insert(argv, "--qmldir=" .. qmldir)
    end

    -- add user flags
    local user_flags = target:values("qt.deploy.flags") or {}
    if user_flags then
        argv = table.join(argv, user_flags)
    end

    table.insert(argv, installfile)

    os.vrunv(windeployqt, argv, {envs = envs})
end
