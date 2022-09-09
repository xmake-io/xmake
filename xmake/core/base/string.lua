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
-- @file        string.lua
--

-- define module: string
local string = string or {}

-- load modules
local deprecated = require("base/deprecated")
local serialize  = require("base/serialize")
local bit        = require("base/bit")

-- save original interfaces
string._dump   = string._dump or string.dump
string._trim   = string._trim or string.trim
string._split  = string._split or string.split
string._lastof = string._lastof or string.lastof

-- find the last substring with the given pattern
function string:lastof(pattern, plain)

    -- is plain text? use the native implementation
    if plain then
        return string._lastof(self, pattern)
    end

    -- find the last substring
    local curr = 0
    repeat
        local next = self:find(pattern, curr + 1, plain)
        if next then
            curr = next
        end
    until (not next)

    -- found?
    if curr > 0 then
        return curr
    end
end

-- split string with the given substring/characters
--
-- pattern match and ignore empty string
-- ("1\n\n2\n3"):split('\n') => 1, 2, 3
-- ("abc123123xyz123abc"):split('123') => abc, xyz, abc
-- ("abc123123xyz123abc"):split('[123]+') => abc, xyz, abc
--
-- plain match and ignore empty string
-- ("1\n\n2\n3"):split('\n', {plain = true}) => 1, 2, 3
-- ("abc123123xyz123abc"):split('123', {plain = true}) => abc, xyz, abc
--
-- pattern match and contains empty string
-- ("1\n\n2\n3"):split('\n', {strict = true}) => 1, , 2, 3
-- ("abc123123xyz123abc"):split('123', {strict = true}) => abc, , xyz, abc
-- ("abc123123xyz123abc"):split('[123]+', {strict = true}) => abc, xyz, abc
--
-- plain match and contains empty string
-- ("1\n\n2\n3"):split('\n', {plain = true, strict = true}) => 1, , 2, 3
-- ("abc123123xyz123abc"):split('123', {plain = true, strict = true}) => abc, , xyz, abc
--
-- limit split count
-- ("1\n\n2\n3"):split('\n', {limit = 2}) => 1, 2\n3
-- ("1.2.3.4.5"):split('%.', {limit = 3}) => 1, 2, 3.4.5
--
function string:split(delimiter, opt)
    local limit, plain, strict
    if opt then
        limit = opt.limit
        plain = opt.plain
        strict = opt.strict
    end
    if plain then
        return string._split(self, delimiter, strict, limit)
    end
    local start = 1
    local result = {}
    local pos, epos = self:find(delimiter, start, plain)
    while pos do
        local substr = self:sub(start, pos - 1)
        if (#substr > 0) or strict then
            if limit and limit > 0 and #result + 1 >= limit then
                break
            end
            table.insert(result, substr)
        end
        start = epos + 1
        pos, epos = self:find(delimiter, start, plain)
    end
    if start <= #self then
        table.insert(result, self:sub(start))
    elseif strict and (not limit or #result < limit) then
        if start == #self + 1 then
            table.insert(result, "")
        end
    end
    return result
end

-- trim the spaces
function string:trim(trimchars)
    return string._trim(self, trimchars, 0)
end

-- trim the left spaces
function string:ltrim(trimchars)
    return string._trim(self, trimchars, -1)
end

-- trim the right spaces
function string:rtrim(trimchars)
    return string._trim(self, trimchars, 1)
end

-- encode: ' ', '=', '\"', '<'
function string:encode()
    return (self:gsub("[%s=\"<]", function (w) return string.format("%%%x", w:byte()) end))
end

-- decode: ' ', '=', '\"'
function string:decode()
    return (self:gsub("%%(%x%x)", function (w) return string.char(tonumber(w, 16)) end))
end

-- replace text
function string:replace(old, new, opt)
    if opt and opt.plain then
        local b, e = self:find(old, 1, true)
        if b == nil then
            return self, 0
        else
            local str, count = self:sub(e + 1):replace(old, new, opt)
            return (self:sub(1, b - 1) .. new .. str), count + 1
        end
    else
        return self:gsub(old, new)
    end
end

-- try to format
function string.tryformat(format, ...)
    local ok, str = pcall(string.format, format, ...)
    if ok then
        return str
    else
        return tostring(format)
    end
end

-- case-insensitive pattern-matching
--
-- print(("src/dadasd.C"):match(string.ipattern("sR[cd]/.*%.c", true)))
-- print(("src/dadasd.C"):match(string.ipattern("src/.*%.c", true)))
--
-- print(string.ipattern("sR[cd]/.*%.c"))
--   [sS][rR][cd]/.*%.[cC]
--
-- print(string.ipattern("sR[cd]/.*%.c", true))
--   [sS][rR][cCdD]/.*%.[cC]
--
function string.ipattern(pattern, brackets)
    local tmp = {}
    local i = 1
    while i <= #pattern do

        -- get current charactor
        local char = pattern:sub(i, i)

        -- escape?
        if char == '%' then
            tmp[#tmp + 1] = char
            i = i + 1
            char = pattern:sub(i,i)
            tmp[#tmp + 1] = char

            -- '%bxy'? add next 2 chars
            if char == 'b' then
                tmp[#tmp + 1] = pattern:sub(i + 1, i + 2)
                i = i + 2
            end
        -- brackets?
        elseif char == '[' then
            tmp[#tmp + 1] = char
            i = i + 1
            while i <= #pattern do
                char = pattern:sub(i, i)
                if char == '%' then
                    tmp[#tmp + 1] = char
                    tmp[#tmp + 1] = pattern:sub(i + 1, i + 1)
                    i = i + 1
                elseif char:match("%a") then
                    tmp[#tmp + 1] = not brackets and char or char:lower() .. char:upper()
                else
                    tmp[#tmp + 1] = char
                end
                if char == ']' then break end
                i = i + 1
            end
        -- letter, [aA]
        elseif char:match("%a") then
            tmp[#tmp + 1] = '[' .. char:lower() .. char:upper() .. ']'
        else
            tmp[#tmp + 1] = char
        end
        i = i + 1
    end
    return table.concat(tmp)
end

-- @deprecated
-- dump to string from the given object (more readable)
--
-- @param deflate       deflate empty characters
--
-- @return              string, errors
--
function string.dump(object, deflate)
    deprecated.add("utils.dump() or string.serialize()", "string.dump()")
    return string.serialize(object, deflate)
end

-- serialize to string from the given object
--
-- @param opt           serialize options
--                      e.g. { strip = true, binary = false, indent = true }
--
-- @return              string, errors
--
function string.serialize(object, opt)
    return serialize.save(object, opt)
end

-- deserialize string to object
--
-- @param str           the serialized string
--
-- @return              object, errors
--
function string:deserialize()
    return serialize.load(self)
end

-- unicode character width in the given index
function string:wcwidth(idx)

    -- based on Markus Kuhn's implementation of wcswidth()
    -- https://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c
    local non_spacing =
    {
        {0x0300, 0x036F},   {0x0483, 0x0486},   {0x0488, 0x0489},
        {0x0591, 0x05BD},   {0x05BF, 0x05BF},   {0x05C1, 0x05C2},
        {0x05C4, 0x05C5},   {0x05C7, 0x05C7},   {0x0600, 0x0603},
        {0x0610, 0x0615},   {0x064B, 0x065E},   {0x0670, 0x0670},
        {0x06D6, 0x06E4},   {0x06E7, 0x06E8},   {0x06EA, 0x06ED},
        {0x070F, 0x070F},   {0x0711, 0x0711},   {0x0730, 0x074A},
        {0x07A6, 0x07B0},   {0x07EB, 0x07F3},   {0x0901, 0x0902},
        {0x093C, 0x093C},   {0x0941, 0x0948},   {0x094D, 0x094D},
        {0x0951, 0x0954},   {0x0962, 0x0963},   {0x0981, 0x0981},
        {0x09BC, 0x09BC},   {0x09C1, 0x09C4},   {0x09CD, 0x09CD},
        {0x09E2, 0x09E3},   {0x0A01, 0x0A02},   {0x0A3C, 0x0A3C},
        {0x0A41, 0x0A42},   {0x0A47, 0x0A48},   {0x0A4B, 0x0A4D},
        {0x0A70, 0x0A71},   {0x0A81, 0x0A82},   {0x0ABC, 0x0ABC},
        {0x0AC1, 0x0AC5},   {0x0AC7, 0x0AC8},   {0x0ACD, 0x0ACD},
        {0x0AE2, 0x0AE3},   {0x0B01, 0x0B01},   {0x0B3C, 0x0B3C},
        {0x0B3F, 0x0B3F},   {0x0B41, 0x0B43},   {0x0B4D, 0x0B4D},
        {0x0B56, 0x0B56},   {0x0B82, 0x0B82},   {0x0BC0, 0x0BC0},
        {0x0BCD, 0x0BCD},   {0x0C3E, 0x0C40},   {0x0C46, 0x0C48},
        {0x0C4A, 0x0C4D},   {0x0C55, 0x0C56},   {0x0CBC, 0x0CBC},
        {0x0CBF, 0x0CBF},   {0x0CC6, 0x0CC6},   {0x0CCC, 0x0CCD},
        {0x0CE2, 0x0CE3},   {0x0D41, 0x0D43},   {0x0D4D, 0x0D4D},
        {0x0DCA, 0x0DCA},   {0x0DD2, 0x0DD4},   {0x0DD6, 0x0DD6},
        {0x0E31, 0x0E31},   {0x0E34, 0x0E3A},   {0x0E47, 0x0E4E},
        {0x0EB1, 0x0EB1},   {0x0EB4, 0x0EB9},   {0x0EBB, 0x0EBC},
        {0x0EC8, 0x0ECD},   {0x0F18, 0x0F19},   {0x0F35, 0x0F35},
        {0x0F37, 0x0F37},   {0x0F39, 0x0F39},   {0x0F71, 0x0F7E},
        {0x0F80, 0x0F84},   {0x0F86, 0x0F87},   {0x0F90, 0x0F97},
        {0x0F99, 0x0FBC},   {0x0FC6, 0x0FC6},   {0x102D, 0x1030},
        {0x1032, 0x1032},   {0x1036, 0x1037},   {0x1039, 0x1039},
        {0x1058, 0x1059},   {0x1160, 0x11FF},   {0x135F, 0x135F},
        {0x1712, 0x1714},   {0x1732, 0x1734},   {0x1752, 0x1753},
        {0x1772, 0x1773},   {0x17B4, 0x17B5},   {0x17B7, 0x17BD},
        {0x17C6, 0x17C6},   {0x17C9, 0x17D3},   {0x17DD, 0x17DD},
        {0x180B, 0x180D},   {0x18A9, 0x18A9},   {0x1920, 0x1922},
        {0x1927, 0x1928},   {0x1932, 0x1932},   {0x1939, 0x193B},
        {0x1A17, 0x1A18},   {0x1B00, 0x1B03},   {0x1B34, 0x1B34},
        {0x1B36, 0x1B3A},   {0x1B3C, 0x1B3C},   {0x1B42, 0x1B42},
        {0x1B6B, 0x1B73},   {0x1DC0, 0x1DCA},   {0x1DFE, 0x1DFF},
        {0x200B, 0x200F},   {0x202A, 0x202E},   {0x2060, 0x2063},
        {0x206A, 0x206F},   {0x20D0, 0x20EF},   {0x302A, 0x302F},
        {0x3099, 0x309A},   {0xA806, 0xA806},   {0xA80B, 0xA80B},
        {0xA825, 0xA826},   {0xFB1E, 0xFB1E},   {0xFE00, 0xFE0F},
        {0xFE20, 0xFE23},   {0xFEFF, 0xFEFF},   {0xFFF9, 0xFFFB},
        {0x10A01, 0x10A03}, {0x10A05, 0x10A06}, {0x10A0C, 0x10A0F},
        {0x10A38, 0x10A3A}, {0x10A3F, 0x10A3F}, {0x1D167, 0x1D169},
        {0x1D173, 0x1D182}, {0x1D185, 0x1D18B}, {0x1D1AA, 0x1D1AD},
        {0x1D242, 0x1D244}, {0xE0001, 0xE0001}, {0xE0020, 0xE007F},
        {0xE0100, 0xE01EF},
    }

    idx = idx or 1

    -- turn codepoint into unicode
    local c = self:byte(idx)
    local seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or
                c < 0xF8 and 4 or error("invalid UTF-8 sequence")
    local val = seq == 1 and c or bit.band(c, (2^(8 - seq) - 1))

    for aux = 2, seq do
        c = self:byte(idx + aux - 1)
        val = val * 2 ^ 6 + bit.band(c, 0x3F)
    end

    -- test for 8-bit control characters
    if val == 0 then return 0 end

    if val < 32 or (val >= 0x7f and val < 0xa0) then
        return -1
    end

    -- binary search in table of non-spacing characters
    local min, max = 1, #non_spacing
    if val >= non_spacing[1][1] and val <= non_spacing[max][2] then
        while max >= min do
            local mid = math.floor((min + max) / 2)
            if val > non_spacing[mid][2] then
                min = mid + 1
            elseif val < non_spacing[mid][1] then
                max = mid - 1
            else
                return 0
            end
        end
    end

    if  val >= 0x1100 and (val <= 0x115f or  -- Hangul Jamo init. consonants
        val == 0x2329 or val == 0x232a or
        (val >= 0x2e80 and val <= 0xa4cf and
        val ~= 0x303f) or                    -- CJK ... Yi
        (val >= 0xac00 and val <= 0xd7a3) or -- Hangul Syllables
        (val >= 0xf900 and val <= 0xfaff) or -- CJK Compatibility Ideographs
        (val >= 0xfe10 and val <= 0xfe19) or -- Vertical forms
        (val >= 0xfe30 and val <= 0xfe6f) or -- CJK Compatibility Forms
        (val >= 0xff00 and val <= 0xff60) or -- Fullwidth Forms
        (val >= 0xffe0 and val <= 0xffe6) or
        (val >= 0x20000 and val <= 0x2fffd) or
        (val >= 0x30000 and val <= 0x3fffd)) then
        return 2
    end

    return 1
end

-- unicode string width in given start index
function string:wcswidth(idx)
    local width = 0
    idx = idx or 1
    while idx <= #self do
        if bit.band(self:byte(idx), 0xc0) ~= 0x80 then
            width = width + self:wcwidth(idx)
        end
        idx = idx + 1
    end
    return width
end

-- return module: string
return string
