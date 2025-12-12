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

-- load modules
local os = require("base/os")

-- save original interfaces
binutils._bin2c = binutils._bin2c or binutils.bin2c
binutils._bin2coff = binutils._bin2coff or binutils.bin2coff
binutils._bin2macho = binutils._bin2macho or binutils.bin2macho
binutils._bin2elf = binutils._bin2elf or binutils.bin2elf
binutils._readsyms = binutils._readsyms or binutils.readsyms
binutils._deplibs = binutils._deplibs or binutils.deplibs
binutils._extractlib = binutils._extractlib or binutils.extractlib

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

-- generate object file from the binary file
-- @param binaryfile  the binary file path
-- @param outputfile  the output object file path
-- @param opt         the options
--                      - format: the object file format (coff, elf, macho), required
--                      - symbol_prefix: the symbol prefix (default: _binary_)
--                      - arch: the target architecture (default: x86_64)
--                      - plat: the target platform (default: macosx, only for macho)
--                      - basename: the base name for symbols
--                      - target_minver: the target minimum version (only for macho)
--                      - xcode_sdkver: the Xcode SDK version (only for macho)
--                      - zeroend: append null terminator (default: false)
function binutils.bin2obj(binaryfile, outputfile, opt)
    opt = opt or {}
    local format = opt.format
    if not format then
        -- auto-detect format based on host platform
        local host = os.host()
        if host == "windows" or host == "mingw" or host == "msys" or host == "cygwin" then
            format = "coff"
        elseif host == "macosx" or host == "iphoneos" or host == "watchos" or host == "appletvos" then
            format = "macho"
        else
            format = "elf"
        end
    end
    format = format:lower()

    if format == "coff" then
        if not binutils._bin2coff then
            return nil, "bin2obj: binutils._bin2coff not available (C implementation not compiled)"
        end
        return binutils._bin2coff(binaryfile, outputfile, opt.symbol_prefix or "_binary_", opt.arch or "x86_64", opt.basename, opt.zeroend or false)
    elseif format == "macho" then
        if not binutils._bin2macho then
            return nil, "bin2obj: binutils._bin2macho not available (C implementation not compiled)"
        end
        return binutils._bin2macho(binaryfile, outputfile, opt.symbol_prefix or "_binary_", opt.plat or "macosx", opt.arch or "x86_64", opt.basename, opt.target_minver, opt.xcode_sdkver, opt.zeroend or false)
    elseif format == "elf" then
        if not binutils._bin2elf then
            return nil, "bin2obj: binutils._bin2elf not available (C implementation not compiled)"
        end
        return binutils._bin2elf(binaryfile, outputfile, opt.symbol_prefix or "_binary_", opt.arch or "x86_64", opt.basename, opt.zeroend or false)
    else
        return nil, string.format("bin2obj: unsupported format '%s' (supported: coff, elf, macho)", format)
    end
end


-- read symbols from object file (auto-detect format: COFF, ELF, or Mach-O)
function binutils.readsyms(binaryfile)
    if binutils._readsyms then
        return binutils._readsyms(binaryfile)
    else
        return nil, "readsyms: C implementation not available"
    end
end

-- get dependent libraries from binary file (auto-detect format: COFF, ELF, or Mach-O)
function binutils.deplibs(binaryfile)
    if binutils._deplibs then
        return binutils._deplibs(binaryfile)
    else
        return nil, "deplibs: C implementation not available"
    end
end

-- extract static library to directory
-- Supports AR format (.a) and MSVC lib format (.lib)
-- @param libraryfile the static library file path (.a or .lib)
-- @param outputdir    the output directory to extract object files
-- @param opt          the options (optional)
--                       - plain: extract all object files to the same directory (default: true)
-- @return             true on success, false and error message on failure
function binutils.extractlib(libraryfile, outputdir, opt)
    if binutils._extractlib then
        local ok, errors = binutils._extractlib(libraryfile, outputdir, opt and opt.plain)
        if ok then
            return true
        else
            return false, errors or "extractlib: unknown error"
        end
    else
        return false, "extractlib: C implementation not available"
    end
end

-- return module
return binutils

