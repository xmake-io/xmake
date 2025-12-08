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
        -- calculate column widths for alignment
        local max_value_len = 0
        local max_name_len = 0
        local max_type_len = 0
        local max_bind_len = 0
        local max_section_len = 0
        local max_size_len = 0

        for i, sym in ipairs(symbols) do
            if sym.value then
                local value_str = string.format("0x%x", sym.value)
                max_value_len = math.max(max_value_len, #value_str)
            end
            if sym.name then
                max_name_len = math.max(max_name_len, #sym.name)
            end
            if sym.type then
                max_type_len = math.max(max_type_len, #sym.type)
            end
            if sym.bind then
                max_bind_len = math.max(max_bind_len, #sym.bind)
            end
            if sym.section then
                local section_str = tostring(sym.section)
                max_section_len = math.max(max_section_len, #section_str)
            end
            if sym.size then
                local size_str = tostring(sym.size)
                max_size_len = math.max(max_size_len, #size_str)
            end
        end

        -- calculate column widths
        local value_width = math.max(max_value_len, 10)
        local type_width = math.max(max_type_len, 4)
        local bind_width = math.max(max_bind_len, 4)
        local section_width = math.max(max_section_len, 7)
        local size_width = math.max(max_size_len, 4)
        
        -- print header
        print("")
        print("Symbols:")
        local header_format = "  %-" .. value_width .. "s  %-" .. type_width .. "s  %-" .. bind_width .. "s  %-" .. section_width .. "s  %-" .. size_width .. "s  %s"
        print(string.format(header_format, "VALUE", "TYPE", "BIND", "SECTION", "SIZE", "NAME"))
        print(string.rep("-", 80))
        
        -- print symbols
        local format_str = "  %-" .. value_width .. "s  %-" .. type_width .. "s  %-" .. bind_width .. "s  %-" .. section_width .. "s  %-" .. size_width .. "s  %s"

        for i, sym in ipairs(symbols) do
            local value_str = sym.value and string.format("0x%x", sym.value) or ""
            local type_str = sym.type or ""
            local bind_str = sym.bind or ""
            local section_str = sym.section and sym.section > 0 and tostring(sym.section) or ""
            local size_str = sym.size and tostring(sym.size) or ""
            local name_str = sym.name or ""

            print(string.format(format_str, value_str, type_str, bind_str, section_str, size_str, name_str))
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

