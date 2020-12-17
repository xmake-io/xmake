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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        macosx.lua
--

-- imports
import("core.theme.theme")
import("core.base.option")
import("core.project.config")
import("core.project.depend")
import("core.tool.toolchain")
import("detect.sdks.find_vstudio")
import("private.utils.progress")

-- install application package for windows
function main(target, opt)

    local targetfile = target:targetfile()
    local installfile = path.join(target:installdir(), "bin", path.filename(targetfile))

    -- need re-generate this app?
    local dependfile = target:dependfile(targetfile)

    depend.on_changed(function ()
        -- do deploy
        
        -- get qt sdk
        local qt = target:data("qt")

        -- get windeployqt
        local windeployqt = path.join(qt.bindir, "windeployqt.exe")
        assert(os.isexec(windeployqt), "windeployqt.exe not found!")

        -- find qml directory
        local qmldir = nil
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

        -- find msvc to set VCINSTALLDIR env
        local envs = nil
        local msvc = toolchain.load("msvc", {plat = target:plat(), arch = target:arch()})
        if msvc then
            local vcvars = msvc:config("vcvars")
            if vcvars and vcvars.VSInstallDir then
                envs = {VCINSTALLDIR = path.join(vcvars.VSInstallDir, "VC")}
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
        if qmldir then
            table.insert(argv, "--qmldir=" .. qmldir)
        end
        table.insert(argv, installfile)

        os.vrunv(windeployqt, argv, {envs = envs})
    end, {dependfile = dependfile, files = targetfile})
end
