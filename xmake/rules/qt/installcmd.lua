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
    else
        -- Windows/Linux: after_install has already run windeployqt which deploys Qt dependencies to bindir
        -- We need to copy all files from bindir (including plugins, translations, etc.) to the package install directory
        local bindir = target:bindir()
        if bindir and os.isdir(bindir) then
            local package_bindir = package:installdir("bin")
            -- copy all files and directories from bindir (includes deployed Qt dependencies, plugins, translations, etc.)
            batchcmds:cp(path.join(bindir, "*"), package_bindir, {rootdir = bindir})
        end
    end
end

