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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")
import(".batchcmds")

-- pack dmg package
function _pack_dmg(package)

    -- check platform
    assert(package:is_plat("macosx"), "dmg format only supports macOS platform!")

    -- get hdiutil
    local hdiutil = find_tool("hdiutil")
    assert(hdiutil, "hdiutil not found! Please install Xcode Command Line Tools.")

    -- archive binary files
    batchcmds.get_installcmds(package):runcmds()
    for _, component in table.orderpairs(package:components()) do
        if component:get("default") ~= false then
            batchcmds.get_installcmds(component):runcmds()
        end
    end

    -- get install root directory
    local rootdir = package:install_rootdir()
    assert(os.isdir(rootdir), "install root directory not found: %s", rootdir)

    -- get output file
    local outputfile = package:outputfile()
    os.tryrm(outputfile)

    -- create directory for DMG in builddir
    local builddir = package:builddir()
    local dmgdir = path.join(builddir, "dmg")
    os.tryrm(dmgdir)
    os.mkdir(dmgdir)

    -- copy files to DMG directory
    local dmgname = path.basename(outputfile, ".dmg")
    local dmgcontentdir = path.join(dmgdir, dmgname)
    os.cp(rootdir, dmgcontentdir)

    -- create DMG using hdiutil
    -- create a read-only DMG with UDZO format (compressed)
    local argv = {
        "create",
        "-volname", package:title() or package:name() or dmgname,
        "-srcfolder", dmgcontentdir,
        "-ov",
        "-format", "UDZO",
        outputfile
    }

    -- run hdiutil
    os.vrunv(hdiutil.program, argv)

    -- verify DMG was created
    assert(os.isfile(outputfile), "generate %s failed!", outputfile)
end

function main(package)
    cprint("packing %s .. ", package:outputfile())
    _pack_dmg(package)
end

