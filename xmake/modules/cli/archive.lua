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
-- @file        archive.lua
--

-- imports
import("core.base.option")
import("utils.archive.archive")

-- the options
local options = {
    {nil, "compress",   "kv",  nil, "Set the compress algorithm.", values = {"fastest", "faster", "default", "better", "best"}},
    {'r', "recurse",    "k",   nil, "Enable recursive pattern."},
    {'w', "workdir",    "kv",  nil, "Set the working directory."},
    {nil, "excludes",   "kv",  nil, "Set the excludes patterns.",
                                    "e.g.",
                                    "    - xmake l cli.archive --excludes=\"*/dir/*|dir/*\" -o archivefile inputfiles"},
    {'o', "archivefile","kv",  nil, "The output archive file."},
    {nil, "inputfiles", "vs",  nil, "The input files."}
}

function main(...)
    local argv = table.pack(...)
    local args = option.parse(argv, options, "Archive file.",
                                             "",
                                             "Usage: xmake l cli.archive [options]")
    local archivefile = assert(args.archivefile, "please set output file!")
    local inputfiles = assert(args.inputfiles, "please set input files!")

    local opt = {}
    opt.recurse = args.recurse
    opt.compress = args.compress
    opt.curdir = args.workdir
    if args.excludes then
        opt.excludes = args.excludes:split("|")
    end
    archive(archivefile, inputfiles, opt)
end
