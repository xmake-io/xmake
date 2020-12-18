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
-- @file        package.lua
--

-- imports
import("utils.ipa.package", {alias = "ipagen"})

-- package for ios
function _package_for_ios(target)

    -- get app directory
    local appdir = target:data("xcode.bundle.rootdir")

    -- get *.ipa file
    local ipafile = path.join(path.directory(appdir), path.basename(appdir) .. ".ipa")

    -- generate *.ipa file
    ipagen(appdir, ipafile)

    -- trace
    cprint("output: ${bright}%s", ipafile)
    cprint("${color.success}package ok!")
end

-- main entry
function main (target, opt)
    if target:is_plat("iphoneos") then
        _package_for_ios(target)
    end
end
