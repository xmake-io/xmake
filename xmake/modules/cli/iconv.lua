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

-- the options
local options =
{
    {'f', "from",   "kv", "utf8", "The source encoding."},
    {'t', "to",     "kv", "utf8", "The target encoding."},
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
    local input_file = args.file
    local output_file = args.output
    local from_code = args.from
    local to_code = args.to

    -- read content
    local content
    if input_file then
        local file, errors = io.open(input_file, "r", {encoding = from_code})
        if not file then
            raise(errors)
        end
        content = file:read("*all")
        file:close()
    else
        -- TODO: support stdin
        raise("Input file required.")
    end

    -- write content
    if output_file then
        local file, errors = io.open(output_file, "w", {encoding = to_code})
        if not file then
            raise(errors)
        end
        file:write(content)
        file:close()
    else
        -- write to stdout
        -- we try to use /dev/stdout to support encoding conversion
        local file, errors = io.open("/dev/stdout", "w", {encoding = to_code})
        if file then
            file:write(content)
            file:close()
        else
            -- fallback to print directly (it may be not correct if the target encoding is not utf8/ansi)
            io.write(content)
        end
    end
end
