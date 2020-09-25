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
-- @file        package.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- main entry
function main (appdir, ipafile, iconfile)

    -- check
    assert(appdir)
    assert(os.isdir(appdir), "%s not found!", appdir)

    -- find zip
    local zip = find_tool("zip")
    assert(zip, "zip not found!")

    -- get the .ipa file path
    local appname = path.basename(appdir)
    if not ipafile then
        ipafile = path.join(path.directory(appdir), appname .. ".ipa")
    end
    ipafile = path.absolute(ipafile)

    -- remove the old ipafile first
    os.tryrm(ipafile)

    -- the temporary directory
    local tmpdir = path.join(os.tmpdir(), "ipagen", appname)

    -- clean the tmpdir first
    os.rm(tmpdir)

    -- make the payload directory
    os.mkdir(path.join(tmpdir, "Payload"))

    -- copy the .app directory into payload
    os.vcp(appdir, path.join(tmpdir, "Payload"))

    -- copy icon file to iTunesArtwork
    if iconfile then
        os.vcp(iconfile, path.join(tmpdir, "iTunesArtwork"))
    end

    -- generate .ipa file
    local argv = {"-r", ipafile, "Payload"}
    if iconfile then
        table.insert(argv, "iTunesArtwork")
    end
    local oldir = os.cd(tmpdir)
    os.vrunv(zip.program, argv)
    os.cd(oldir)

    -- remove the temporary directory
    os.rm(tmpdir)

    -- check
    assert(os.isfile(ipafile), "generate %s failed!", ipafile)
end

