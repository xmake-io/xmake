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
-- @file        archive_xmz.lua
--

-- imports
import("core.base.option")

-- archive archive file
--
-- @param archivefile   the archive file. e.g. *.tar.gz, *.zip, *.7z, *.tar.bz2, ..
-- @param inputfiles    the input file or directory or list
-- @param options       the options, e.g.. {curdir = "/tmp", recurse = true, compress = "fastest|faster|default|better|best", excludes = {"*/dir/*", "dir/*"}}
--
function main(archivefile, inputfiles, opt)
    opt = opt or {}
end
