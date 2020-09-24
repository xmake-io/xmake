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
-- @file        install.lua
--

-- imports
import("core.base.task")
import("lib.detect.find_tool")
import("utils.ipa.install", {alias = "install_ipa"})

-- install for ios
function _install_for_ios(target)

    -- get app directory
    local appdir = target:data("xcode.bundle.rootdir")

    -- get *.ipa file
    local ipafile = path.join(path.directory(appdir), path.basename(appdir) .. ".ipa")
    if not os.isfile(ipafile) or os.mtime(target:targetfile()) > os.mtime(ipafile) then
        task.run("package", {target = target:name()})
    end
    assert(os.isfile(ipafile), "please run `xmake package` first!")

    -- do install
    install_ipa(ipafile)
end

-- install for macosx
function _install_for_macosx(target)

    -- get app directory
    local appdir = target:data("xcode.bundle.rootdir")

    -- do install
    os.vcp(appdir, target:installdir() or "/Applications/")
end

-- main entry
function main (target)
    if is_plat("iphoneos") then
        _install_for_ios(target)
    elseif is_plat("macosx") then
        _install_for_macosx(target)
    end
end
