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
-- @file        iconv.lua
--

-- imports
import("core.base.option")

-- supported encodings
local encodings = {"ansi", "ascii", "gb2312", "gbk", "iso8859", "ucs2", "ucs4", "utf16", "utf16be", "utf16le", "utf32", "utf32be", "utf32le", "utf8"}

-- the options
local options = {
    {'f', "from",   "kv", "utf8", "The source encoding.", values = encodings},
    {'t', "to",     "kv", "utf8", "The target encoding.", values = encodings},
    {'o', "output", "kv", nil,    "The output file."},
    {nil, "file",   "v",  nil,    "The input file."}
}

-- main entry
function main(...)

    -- parse arguments
    local argv = table.pack(...)
    local args = option.parse(argv, options, "Convert encoding of a file.",
                                             "",
                                             "Usage: xmake l cli.iconv [options] [file]")

    -- get arguments
    local input_file = assert(args.file, "input file required!")
    local output_file = assert(args.output, "output file required!")
    local from_code = args.from
    local to_code = args.to

    -- read and write content
    local content = io.readfile(input_file, {encoding = from_code})
    io.writefile(output_file, content, {encoding = to_code})
end
