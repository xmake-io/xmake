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
-- @file        install.lua
--

-- imports
import("utils.ipa.package", {alias = "ipagen"})
import("lib.detect.find_tool")

-- main entry
function main (ipafile)

    -- check
    assert(os.exists(ipafile), "%s not found!", ipafile)

    -- find ideviceinstaller
    local ideviceinstaller = assert(find_tool("ideviceinstaller"), "ideviceinstaller not found!")

    -- is *.app directory? package it first
    local istmp = false
    if os.isdir(ipafile) then
        local appdir = ipafile
        ipafile = os.tmpfile() .. ".ipa"
        ipagen(appdir, ipafile)
        istmp = true
    end

    -- do install
    os.vrunv(ideviceinstaller.program, {"-i", ipafile})
    if istmp then
        os.tryrm(ipafile)
    end
end

