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
-- @file        extract.lua
--

-- imports
import("core.base.option")
import("utils.archive.extract")

-- the options
local options = {
    {'w', "workdir",    "kv",  nil, "Set the working directory."},
    {nil, "excludes",   "kv",  nil, "Set the excludes patterns.",
                                    "e.g.",
                                    "    - xmake l cli.extract --excludes=\"*/dir/*|dir/*\" -o outputdir archivefile"},
    {'o', "outputdir",  "kv", nil,  "The output directory."},
    {nil, "archivefile","v",  nil,  "The archive file."}
}

function main(...)
    local argv = table.pack(...)
    local args = option.parse(argv, options, "Extract file.",
                                             "",
                                             "Usage: xmake l cli.extract [options]")
    local archivefile = assert(args.archivefile, "please set archive file!")
    local outputdir = assert(args.outputdir, "please set output directory!")

    local opt = {}
    opt.recurse = args.recurse
    opt.curdir = args.workdir
    if args.excludes then
        opt.excludes = args.excludes:split("|")
    end
    extract(archivefile, outputdir, opt)
end
