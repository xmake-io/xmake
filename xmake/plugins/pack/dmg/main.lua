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
import("plugins.pack.launcher", {alias = "launcher", rootdir = os.programdir()})

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

    -- install launcher wrapper if runenvs/runargs are set
    local launcher_exe = launcher.main_executable(package)
    if launcher_exe then
        local binname = path.filename(launcher_exe)
        local launcher_path = path.join(rootdir, package:get("bindir") or "bin", binname) .. ".app/Contents/MacOS/" .. binname
        -- the wrapper lives in bin/<name>.app/Contents/MacOS, the real binary
        -- is at bin/<name>, so reference it relative to the wrapper location
        local exec_path = string.format('"$(dirname "$0")/../../../%s"', path.filename(launcher_exe))
        local launcher_script = launcher.generate(package, exec_path)
        if launcher_script then
            os.mkdir(path.directory(launcher_path))
            io.writefile(launcher_path, launcher_script)
            os.vrunv("chmod", {"+x", launcher_path})
        end
    end

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

