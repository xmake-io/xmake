--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("detect.tool.find_zip")

-- main
function main()

    -- find zip
    local zip = find_zip()
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
