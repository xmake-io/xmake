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
-- @file        binutils.lua
--

-- define module
local binutils = binutils or {}

-- save original interfaces
binutils._bin2c = binutils._bin2c or binutils.bin2c
binutils._bin2coff = binutils._bin2coff or binutils.bin2coff
binutils._bin2macho = binutils._bin2macho or binutils.bin2macho
binutils._bin2elf = binutils._bin2elf or binutils.bin2elf

-- generate c/c++ code from the binary file
function binutils.bin2c(binaryfile, outputfile, opt)
    opt = opt or {}
    if binutils._bin2c then
        return binutils._bin2c(binaryfile, outputfile, opt.linewidth or 32, opt.nozeroend or false)
    else
        -- fallback to old implementation if C implementation not available
        return nil, "bin2c: C implementation not available"
    end
end

-- generate COFF object file from the binary file
function binutils.bin2coff(binaryfile, outputfile, opt)
    opt = opt or {}
    return binutils._bin2coff(binaryfile, outputfile, opt.symbol_prefix or "_binary_", opt.arch or "x86_64", opt.basename, opt.zeroend or false)
end

-- generate Mach-O object file from the binary file
function binutils.bin2macho(binaryfile, outputfile, opt)
    opt = opt or {}
    return binutils._bin2macho(binaryfile, outputfile, opt.symbol_prefix or "_binary_", opt.plat or "macosx", opt.arch or "x86_64", opt.basename, opt.target_minver, opt.xcode_sdkver, opt.zeroend or false)
end

-- generate ELF object file from the binary file
function binutils.bin2elf(binaryfile, outputfile, opt)
    opt = opt or {}
    return binutils._bin2elf(binaryfile, outputfile, opt.symbol_prefix or "_binary_", opt.arch or "x86_64", opt.basename, opt.zeroend or false)
end

-- return module
return binutils

