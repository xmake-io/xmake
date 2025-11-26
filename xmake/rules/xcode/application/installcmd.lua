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
    
    -- only for macosx when packing dmg
    if not target:is_plat("macosx") then
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
end

