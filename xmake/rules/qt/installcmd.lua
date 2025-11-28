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
-- @file        installcmd.lua
--

-- imports
import("rules.qt.install.windeployqt", {rootdir = os.programdir()})

-- install application for xpack
function main(target, batchcmds, opt)
    local package = opt.package

    -- only for xpack (package exists)
    if not package then
        return
    end

    -- get install directory
    local installdir = package:installdir()
    if not installdir then
        return
    end

    -- macOS: install .app bundle
    if target:is_plat("macosx") then
        local target_app = path.join(target:targetdir(), target:basename() .. ".app")
        if os.isdir(target_app) then
            -- copy .app to install directory
            local appname = path.filename(target_app)
            local dstappdir = path.join(installdir, appname)
            batchcmds:cp(target_app, dstappdir, {symlink = true})
        end
    elseif target:is_plat("windows", "mingw") then
        -- Windows/Mingw: need to run windeployqt to deploy Qt dependencies
        -- First, prepare files in a temporary directory, then copy to package bindir via batchcmds

        -- prepare deployment in a temporary directory
        local deploydir = path.join(target:autogendir(), "qt", "deploy", target:name())
        os.mkdir(deploydir)

        -- copy target binary to deploydir first
        local targetfile = path.join(deploydir, target:filename())
        os.cp(target:targetfile(), targetfile)

        -- copy qt.shared deps
        local installfiles = {targetfile}
        for _, dep in ipairs(target:orderdeps()) do
            if dep:rule("qt.shared") then
                local depfile = path.join(deploydir, path.filename(dep:targetfile()))
                os.cp(dep:targetfile(), depfile)
                table.insert(installfiles, depfile)
            end
        end

        -- run windeployqt to deploy Qt dependencies to deploydir
        windeployqt.run_deploy(target, deploydir, installfiles)

        -- copy all deployed files and directories from deploydir to root install directory via batchcmds
        local installdir = package:installdir()
        batchcmds:cp(path.join(deploydir, "*"), installdir, {rootdir = deploydir})
    else
        -- Linux: copy all files from bindir (plugins, translations, etc. should be handled separately)
        local bindir = target:bindir()
        if bindir and os.isdir(bindir) then
            local package_bindir = package:installdir("bin")
            -- copy all files and directories from bindir
            batchcmds:cp(path.join(bindir, "*"), package_bindir, {rootdir = bindir})
        end
    end
end

