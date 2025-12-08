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
-- @file        readsyms.lua
--

-- imports
import("core.base.binutils")

-- get symbols from binary file (auto-detect format: ELF, COFF, Mach-O)
--
-- @param binaryfile  the binary file path (required)
-- @return            the symbols table
function _get_symbols(binaryfile)
    assert(binaryfile, "usage: xmake l utils.binary.readsyms <binaryfile>")

    binaryfile = path.absolute(binaryfile)
    assert(os.isfile(binaryfile), "%s not found!", binaryfile)

    return binutils.readsyms(binaryfile)
end

-- dump symbols to console
--
-- @param binaryfile  the object file path (required)
function dump(binaryfile)
    local symbols = _get_symbols(binaryfile)
    if symbols and #symbols > 0 then
        print("")
        print("Symbols:")
        for i, sym in ipairs(symbols) do
            local value_str = ""
            if sym.value then
                value_str = string.format("0x%x", sym.value)
            end
            local size_str = ""
            if sym.size then
                size_str = string.format(" size=%d", sym.size)
            end
            local section_str = ""
            if sym.section and sym.section > 0 then
                section_str = string.format(" section=%d", sym.section)
            end
            local type_str = ""
            if sym.type then
                type_str = string.format(" type=%s", sym.type)
            end
            local bind_str = ""
            if sym.bind then
                bind_str = string.format(" bind=%s", sym.bind)
            end
            print(string.format("  %s %s%s%s%s%s", sym.name or "", value_str, size_str, section_str, type_str, bind_str))
        end
        print("")
        cprint("${bright}%d symbols found!", #symbols)
    else
        print("")
        cprint("${bright}No symbols found!")
    end
end

-- read symbols from object file (auto-detect format: ELF, COFF, Mach-O)
--
-- @param binaryfile  the object file path (required)
-- @return           the symbols table
function main(binaryfile)
    return _get_symbols(binaryfile)
end

