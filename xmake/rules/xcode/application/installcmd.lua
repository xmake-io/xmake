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
    
    -- only for macosx when packing
    if not target:is_plat("macosx") then
        return
    end

    -- only for xpack (package exists)
    if not package then
        return
    end

    -- get app directory
    local appdir = target:data("xcode.bundle.rootdir")
    if not appdir or not os.isdir(appdir) then
        return
    end

    -- get install directory
    -- for dmg packing, we install .app to the root of install directory
    local installdir = package:installdir()
    if not installdir then
        return
    end

    -- copy .app to install directory
    local appname = path.filename(appdir)
    local dstappdir = path.join(installdir, appname)
    batchcmds:cp(appdir, dstappdir, {symlink = true})

    -- install target files (skip binary installation)
    local srcfiles, dstfiles = target:installfiles(installdir)
    if srcfiles and dstfiles then
        for idx, srcfile in ipairs(srcfiles) do
            batchcmds:cp(srcfile, dstfiles[idx], {symlink = true})
        end
    end
    -- install dependent target files
    for _, dep in ipairs(target:orderdeps()) do
        local srcfiles, dstfiles = dep:installfiles(installdir, {interface = true})
        if srcfiles and dstfiles then
            for idx, srcfile in ipairs(srcfiles) do
                batchcmds:cp(srcfile, dstfiles[idx], {symlink = true})
            end
        end
    end
end

