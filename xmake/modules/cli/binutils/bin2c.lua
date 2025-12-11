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
-- @file        bin2c.lua
--

-- imports
import("core.base.option")
import("utils.binary.bin2c")

local options = {
    {'w', "linewidth",  "kv", nil,   "Set the line width"},
    {nil, "nozeroend",  "k",  false, "Disable to patch zero terminating character"},
    {'i', "binarypath", "kv", nil,   "Set the binary file path."},
    {'o', "outputpath", "kv", nil,   "Set the output file path."}
}

function main(...)

    -- parse arguments
    local argv = {...}
    local opt  = option.parse(argv, options, "Print c/c++ code files from the given binary file."
                                           , ""
                                           , "Usage: xmake l cli.binutils.bin2c [options]")

    -- do bin2c
    bin2c.main(opt.binarypath, opt.outputpath, opt)
end
