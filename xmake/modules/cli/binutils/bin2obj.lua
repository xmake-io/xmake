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
-- @file        bin2obj.lua
--

-- imports
import("core.base.option")
import("utils.binary.bin2obj")

local options = {
    {'i', "binarypath",    "kv", nil,   "Set the binary file path."},
    {'o', "outputpath",    "kv", nil,   "Set the output object file path."},
    {'f', "format",        "kv", nil,   "Set the object file format (coff, elf, macho)."},
    {nil, "symbol_prefix", "kv", nil,   "Set the symbol prefix (default: _binary_)."},
    {'a', "arch",          "kv", nil,   "Set the target architecture."},
    {'p', "plat",          "kv", nil,   "Set the target platform (macosx, iphoneos, etc.)."},
    {nil, "target_minver", "kv", nil,   "Set the target minimum version (e.g., 10.0, 18.2)."},
    {nil, "xcode_sdkver",  "kv", nil,   "Set the Xcode SDK version (e.g., 10.0, 18.2)."},
    {nil, "zeroend",       "k",  nil,   "Append a null terminator ('\\0') at the end of data."}
}

function main(...)

    -- parse arguments
    local argv = {...}
    local opt  = option.parse(argv, options, "Convert binary file to object file for direct linking."
                                                   , ""
                                                   , "Usage: xmake l cli.binutils.bin2obj [options]")

    -- check arguments
    if not opt.binarypath or not opt.outputpath then
        cprint("${bright}Usage: $${clear}xmake l cli.binutils.bin2obj [options]")
        option.show_options(options, "bin2obj")
        return 
    end

    -- do bin2obj
    bin2obj.main(opt.binarypath, opt.outputpath, opt)
end
