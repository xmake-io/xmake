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
-- @file        uninstallcmd.lua
--

-- uninstall application for xpack
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

    -- macOS: uninstall .app bundle
    if target:is_plat("macosx") then
        local target_app = path.join(target:targetdir(), target:basename() .. ".app")
        if os.isdir(target_app) then
            -- remove .app from install directory
            local appname = path.filename(target_app)
            local dstappdir = path.join(installdir, appname)
            batchcmds:rmdir(dstappdir, {emptydirs = true})
        end
    elseif target:is_plat("windows", "mingw") then
        -- Windows/Mingw: remove all deployed files and directories from install directory
        local installdir = package:installdir()
        
        -- use the same deploydir as installcmd to determine what files were installed
        -- deploydir exists at build/pack time when uninstallcmd is called
        local deploydir = path.join(target:autogendir(), "qt", "deploy", target:name())
        
        -- if deploydir exists, use it to get the list of files/dirs to remove
        if os.isdir(deploydir) then
            -- match all files and directories in deploydir (same as installcmd)
            for _, item in ipairs(os.filedirs(path.join(deploydir, "*"))) do
                local relpath = path.relative(item, deploydir)
                local dstpath = path.join(installdir, relpath)
                if os.isfile(item) then
                    batchcmds:rm(dstpath, {emptydirs = true})
                elseif os.isdir(item) then
                    batchcmds:rmdir(dstpath, {emptydirs = true})
                end
            end
        else
            -- fallback: if deploydir doesn't exist, remove common Qt deployment items
            -- this should rarely happen, but provides a safety net
            batchcmds:rm(path.join(installdir, target:filename()), {emptydirs = true})
            for _, dep in ipairs(target:orderdeps()) do
                if dep:rule("qt.shared") then
                    batchcmds:rm(path.join(installdir, path.filename(dep:targetfile())), {emptydirs = true})
                end
            end
            -- note: we can't easily remove all deployed files without deploydir,
            -- but at least we remove the main binaries
        end
    else
        -- Linux: remove all files from bin directory
        local bindir = target:bindir()
        if bindir and os.isdir(bindir) then
            local package_bindir = package:installdir("bin")
            -- remove all files and directories from package bindir
            for _, item in ipairs(os.filedirs(path.join(package_bindir, "*"))) do
                if os.isfile(item) then
                    batchcmds:rm(item, {emptydirs = true})
                elseif os.isdir(item) then
                    batchcmds:rmdir(item, {emptydirs = true})
                end
            end
        end
    end
end

