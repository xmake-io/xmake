--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.tool.tool")

-- main
function main()

    -- check the zip
    local zip = tool.check("zip", nil, function (shellname)
                        os.run("%s -v", shellname)
                    end)
    assert(zip, "zip not found!")

    -- get the .app file path
    local app = option.get("app")
    assert(app, "please input the .app path!")
    assert(os.isdir(app), "%s not found!", app)

    -- get the app name
    local appname = path.basename(app)

    -- get the .ipa file path
    local ipa = option.get("ipa")
    if not ipa then
        ipa = path.join(path.directory(app), appname .. ".ipa")
    end

    -- get icon file path
    local icon = option.get("icon")
    assert(icon, "please input the icon path!")
    assert(os.isfile(icon), "%s not found!", icon)

    -- the temporary directory
    local tmpdir = path.join(os.tmpdir(), "app2ipa", appname)

    -- clean the tmpdir first
    os.rm(tmpdir)

    -- make the payload directory
    os.mkdir(path.join(tmpdir, "Payload"))

    -- copy the .app directory into payload
    os.cp(app, path.join(tmpdir, "Payload"))

    -- copy icon to iTunesArtwork
    os.cp(icon, path.join(tmpdir, "iTunesArtwork"))

    -- generate .ipa file
    os.cd(tmpdir)
    os.run("%s -r %s Payload iTunesArtwork", zip, ipa)
    os.cd("-")

    -- remove the temporary directory
    os.rm(tmpdir)

    -- check
    assert(os.isfile(ipa), "generate %s failed!", ipa)

    -- trace
    cprint("${bright}generate %s ok!${ok_hand}", ipa)
end
