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
-- @file        configurations.lua
--

function main()
    return
    {
        -- the directories to look for the .pc files in, they are given to pkg-config
        -- as its PKG_CONFIG_PATH
        --
        -- e.g. add_requires("pkgconfig::ncurses", {configs = {configdirs = "/usr/local/opt/ncurses/lib/pkgconfig"}})
        configdirs = {description = "Set the search directories of the .pc files."}
    }
end
