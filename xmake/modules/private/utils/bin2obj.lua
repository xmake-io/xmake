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

local options = {
    {'i', "binarypath", "kv", nil,   "Set the binary file path."},
    {'o', "outputpath", "kv", nil,   "Set the output object file path."},
    {'f', "format",    "kv", nil,   "Set the object file format (coff, elf, macho)."},
    {nil, "symbol-prefix", "kv", nil, "Set the symbol prefix (default: _binary_)."},
    {'a', "arch",       "kv", nil,   "Set the target architecture."}
}

function _do_bin2obj_coff(binarypath, outputpath, opt)
    -- get symbol prefix
    local symbol_prefix = opt["symbol-prefix"] or opt.symbol_prefix or "_binary_"

    -- get architecture
    local arch = opt.arch

    -- get basename from binary path
    local basename = path.basename(binarypath)
    -- remove extension
    basename = basename:gsub("%.[^%.]+$", "")

    -- trace
    print("converting binary file %s to COFF object file %s ..", binarypath, outputpath)

    -- do dump
    if utils.bin2coff then
        utils.bin2coff(binarypath, outputpath, symbol_prefix, arch, basename)
    else
        raise("bin2obj: utils.bin2coff not available (C implementation not compiled)")
    end

    -- trace
    cprint("${bright}%s generated!", outputpath)
end

function _do_bin2obj_elf(binarypath, outputpath, opt)
    raise("bin2obj: ELF format not yet implemented")
end

function _do_bin2obj_macho(binarypath, outputpath, opt)
    raise("bin2obj: Mach-O format not yet implemented")
end

function _do_bin2obj(binarypath, outputpath, opt)

    -- init source directory and options
    opt = opt or {}
    binarypath = path.absolute(binarypath)
    outputpath = path.absolute(outputpath)
    assert(os.isfile(binarypath), "%s not found!", binarypath)

    -- get format (default: coff)
    local format = opt.format or "coff"
    format = format:lower()

    -- validate format
    if format ~= "coff" and format ~= "elf" and format ~= "macho" then
        raise("bin2obj: unsupported format '%s' (supported: coff, elf, macho)", format)
    end

    -- do conversion based on format
    if format == "coff" then
        _do_bin2obj_coff(binarypath, outputpath, opt)
    elseif format == "elf" then
        _do_bin2obj_elf(binarypath, outputpath, opt)
    elseif format == "macho" then
        _do_bin2obj_macho(binarypath, outputpath, opt)
    end
end

function main(...)

    -- parse arguments
    local argv = {...}
    local opt  = option.parse(argv, options, "Convert binary file to object file for direct linking."
                                                   , ""
                                                   , "Usage: xmake l private.utils.bin2obj [options]")

    -- do bin2obj
    _do_bin2obj(opt.binarypath, opt.outputpath, opt)
end

