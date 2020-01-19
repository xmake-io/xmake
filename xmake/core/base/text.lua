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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      OpportunityLiu
-- @file        text.lua
--

-- define module
local text = text or {}

-- load modules
local string    = require("base/string")
local colors    = require("base/colors")
local math      = require("base/math")
local table     = require("base/table")


function text._iswbr(ch)
    if not text._CHARWBR then
        text._CHARWBR = {
            [(' '):byte()] = 100,
            [('\n'):byte()] = 100,
            [('\t'):byte()] = 100,
            [('\v'):byte()] = 100,
            [('\f'):byte()] = 100,
            [('\r'):byte()] = 100,
            [('-'):byte()] = 90,
            [(')'):byte()] = 50,
            [(']'):byte()] = 50,
            [('}'):byte()] = 50,
            [(','):byte()] = 50,
            [('='):byte()] = 40,
            [('|'):byte()] = 40,
        }
    end
    return text._CHARWBR[ch] or false
end

function text._charwidth(ch)
    if ch == 0x09 then
        -- TAB
        return 4
    elseif ch == 0x08 then
        -- BS
        return -1
    elseif ch <= 0x1F or ch == 0x7F then
        -- other control chars
        return 0
    else
        return 1
    end
end

function text._nextwbr(self, iter)
    local ptr = iter.pos + 1
    local width = iter.width
    local str = self.str
    local e = self.j

    if ptr > e then
        return nil
    end

    while ptr <= e do
        local byte = str:byte(ptr)

        -- ansi sequence, skip it
        if byte == 27 and ptr + 2 <= e and str:byte(ptr + 1) == 91 then
            local ansiend = false
            ptr = ptr + 2
            while ptr <= e do
                local b = str:byte(ptr)
                if b == 109 then
                    ansiend = true
                    break
                end
                ptr = ptr + 1
            end
            if not ansiend then
                -- ansi sequence not finished in [i, j], no more wbr in the range
                return nil
            end
        else
            width = width + text._charwidth(byte)
            local wbr = text._iswbr(byte)
            if wbr then
                return { pos = ptr, width = width, quality = wbr }
            end
        end
        ptr = ptr + 1
    end

    -- wbr at end of string
    return { pos = e, width = width, quality = 100 }
end

function text._iterwbr(str, i, j, wordbreak)
    if not i then
        i = 1
    elseif i < 0 then
        i = #str + 1 + i
    end
    if not j then
        j = #str
    elseif j < 0 then
        j = #str + 1 + j
    end
    return text._nextwbr, { str = str, i = i, j = j, wordbreak = wordbreak }, { pos = i - 1, width = 0 }
end

-- @see https://unicode.org/reports/tr14/
function text._lastwbr(str, width, wordbreak)

    -- check
    assert(#str >= width)

    if wordbreak == "breakall" then
        -- To prevent overflow, word may be broken at any character
        return width
    else

        if (text._iswbr(str:byte(width + 1)) or -1) >= 100 then
            -- exact break
            return width
        end

        local wbr_candidate
        for wbr in text._iterwbr(str, 1, #str, wordbreak) do
            if not wbr_candidate then
                -- not candidate yet? always use a wbr
                wbr_candidate = wbr
            elseif (wbr.quality >= wbr_candidate.quality or wbr.quality >= 80) and wbr.width <= width then
                -- in range, replace with a higher quality wbr
                wbr_candidate = wbr
            end
            if wbr.width > width then
                break
            end
        end

        if wbr_candidate then
            return wbr_candidate.pos
        end

        -- not found in all str
        return #str
    end
end

-- break lines
function text.wordwrap(str, width, opt)

    opt = opt or {}

    -- split to lines
    if type(str) == "table" then
        str = table.concat(str, "\n")
    end
    local lines = tostring(str):split("\n", {plain = true, strict = true})

    local result = table.new(#lines, 0)
    local actual_width = 0

    -- handle lines
    for _, v in ipairs(lines) do

        -- remove tailing spaces, include "\r", which will be produced by `("l1\r\nl2"):split(...)`
        v = v:rtrim()

        while #v > width do

            -- find word break chance
            local wbr = text._lastwbr(v, width, opt.wordbreak)

            -- break line
            local line = v:sub(1, wbr):rtrim()
            actual_width = math.max(#line, actual_width)
            table.insert(result, line)
            v = v:sub(wbr + 1):ltrim()

            -- prevent empty line
            if #v == 0 then
                v = nil
                break
            end
        end

        -- put remaining parts
        if v then
            actual_width = math.max(#v, actual_width)
            table.insert(result, v)
        end
    end

    -- ok
    return result, actual_width
end

function text._format_cell(cell, width, opt)
    local result = table.new(#cell, 0)
    local max_width = 0
    for _, v in ipairs(cell) do
        local lines, aw = text.wordwrap(tostring(v), width[2], opt)
        table.move(lines, 1, #lines, #result + 1, result)
        max_width = math.max(max_width, aw)
    end
    cell.formatted = result
    cell.width = max_width
end

function text._format_col(col, width, opt)
    local max_width = 0
    for i = 1, table.maxn(col) do
        local v = col[i]
        -- skip span cells
        if v and not v.span then
            text._format_cell(v, width, opt)
            max_width = math.max(max_width, v.width)
        end
    end
    col.width = max_width
end


-- make a table with colors
--
-- @param data         table data, array of array of cells with optional styles
--                       eg: {
--                             {"1", nil, "3"},  -- use nil to make previous cell to span next column
--                             {"4", "5", {"line1", "line2", style="${yellow}", align = "r"}}, -- multi-line content & set style or align for cell
--                             {"7", "8", {"9", style="${reset}${red}"}, style="${bright}", align = "c"}, -- set style or align for row
--                             style = {"${underline}"}, -- set style for columns
--                                                       -- or use "${underline}" for all columns
--                             width = { 20, {10, 50}, "auto"},
--                               -- 2 numbers - min and max width (nil for not set, eg: {nil, 50});
--                               -- a number - width, num is equivalent to {num, num};
--                               -- nil - no limit, equivalent to {nil, nil}
--                               -- "auto" - use remain space of console, only one "auto" column is allowed
--                             align = {"l", "r", "c"} -- align mode for each column, "left", "center" or "right"
--                                                     -- or use a string for the whole table
--                             sep = "${dim} | ", -- table colunm sepertor, default is " | ", use "" to hide
--                           }
--                     priority of style and align: cell > row > col
-- @param opt          options for color rendering and word wrapping
function text.table(data, opt)

    assert(data)

    -- init options
    opt = opt or { ignore_unknown = true }
    data.sep = data.sep or " | "
    opt.patch_reset = false

    -- col ordered cells
    local cols = table.new(1, 0)
    local n_row = table.maxn(data)
    local n_col = 1

    -- count cols
    for i = 1, n_row do
        local row = data[i]
        if row == nil then
            data[i] = {{""}}
        else
            n_col = math.max(n_col, table.maxn(row))
        end
    end

    -- reorder
    for i = 1, n_row do
        local row = data[i]
        local p_cell = nil
        for j = 1, n_col do
            local cell = row[j]
            if cell ~= nil and type(cell) ~= "table" then
                -- wrap cells if needed
                cell = {tostring(cell)}
            elseif cell == nil and j == 1 then
                cell = {""}
            end
            local col = cols[j]
            if not col then
                col = table.new(n_row, 0)
                cols[j] = col
            end
            if cell then
                col[i] = cell
                p_cell = cell
            else
                p_cell.span = (p_cell.span or 1) + 1
            end
        end
    end

    -- load column options
    data.width = data.width or table.new(n_col, 0)
    data.align = data.align or table.new(n_col, 0)
    data.style = data.style or table.new(n_col, 0)

    local style = ""
    if type(data.style) == "string" then
        style = data.style
        data.style = table.new(n_col, 0)
        data.sep = style .. data.sep .. "${reset}"
    end

    local align = "l"
    if type(data.align) == "string" then
        align = data.align
        data.align = table.new(n_col, 0)
    end

    local sep = colors.translate(data.sep, opt)
    local sep_len = #colors.ignore(data.sep, opt)

    -- index of auto col
    local auto_col = nil
    for i = 1, n_col do

        -- load width
        local w = data.width[i]
        if w ~= "auto" then
            local wl, wu
            if w == nil then
                wl, wu = 0, math.huge
            elseif type(w) == "number" then
                if math.isnan(w) or math.isinf(w) then
                    wl, wu = 0, math.huge
                else
                    wl, wu = w, w
                end
            else
                wl, wu = w[1], w[2]
            end
            wl = wl or 0
            wu = wu or math.huge
            data.width[i] = {wl, wu}
        else
            assert(not auto_col, "Only one 'auto' colunm is allowed.")
            auto_col = i
        end

        -- load align
        cols[i].align = (data.align[i] or align):sub(1, 1):lower()
        -- load style
        cols[i].style = data.style[i] or style
    end

    -- format table

    -- 1. format non-auto cols
    for i, col in ipairs(cols) do
        if i ~= auto_col then
            text._format_col(col, data.width[i], opt)
        end
    end

    if auto_col then

        -- 2. caculate auto col width
        local auto_width = os.getwinsize().width
        for i = 1, n_col do
            if i ~= auto_col then
                auto_width = auto_width - cols[i].width
            end
        end
        auto_width = math.max(0, auto_width - sep_len * (n_col - 1))
        data.width[auto_col] = {0,auto_width}

        -- 3. format auto col
        text._format_col(cols[auto_col], data.width[auto_col], opt)
    end

    -- 4. format span cell
    for i, col in ipairs(cols) do

        for j = 1, n_row do
            local cell = col[j]
            if cell and cell.span then
                local w, wl = 0, 0
                for ci = 0, (cell.span - 1) do
                    -- actual width of spanned cols
                    w = w + cols[i + ci].width
                    -- min width of spanned cols
                    wl = wl + data.width[i + ci][1]
                end
                text._format_cell(cell, {0, math.max(w, wl) + sep_len * (cell.span - 1)}, opt)
            end
        end
    end

    -- render cells

    -- row ordered cells
    local rows = table.new(n_row, 0)

    -- reorder
    for i = 1, n_row do
        local d_row = data[i] or {}
        local row = table.new(n_col, 0)
        local line = 1
        for j = 1, n_col do
            local cell = cols[j][i]
            if cell then
                assert(cell.formatted)
                line = math.max(#cell.formatted, line)
            end
            row[j] = cell
        end
        row.line = line

        -- load align
        if d_row.align then
            row.align = d_row.align:sub(1, 1):lower()
        end

        -- load style
        row.style = d_row.style or ""

        rows[i] = row
    end

    local results = table.new(n_row, 0)
    local reset = colors.translate("${reset}", opt)
    for i, row in ipairs(rows) do
        for l = 1, row.line do
            local cells = table.new(n_col, 0)
            local j = 1
            while j <= n_col do

                local cell = row[j]
                assert(cell)
                local col = cols[j]

                if l == 1 then
                    cell.align = cell.align or row.align or col.align
                    cell.style = colors.translate((col.style or "") .. (row.style or "") .. (cell.style or ""), opt)
                end

                local str = cell.formatted[l] or ""
                local width = col.width
                local span = cell.span or 1
                if cell.span then
                    for ci = (j + 1), (j + span - 1) do
                        width = width + cols[ci].width
                    end
                    width = width + sep_len * (span - 1)
                end

                local padded
                if cell.align == "r" then
                    -- right align
                    padded = string.rep(" ", width - #str) .. str
                elseif cell.align == "c" then
                    -- centered
                    local padding = width - #str
                    local lp = math.floor(padding / 2)
                    local rp = math.ceil(padding / 2)
                    padded = string.rep(" ", lp) .. str .. string.rep(" ", rp)
                else
                    --left align, emit tailing spaces for last colunm
                    padded = str .. ((j + span == n_col + 1) and "" or string.rep(" ", width - #str))
                end
                table.insert(cells, cell.style .. padded .. reset)
                j = j + span
            end
            table.insert(results, table.concat(cells, sep))
        end
    end

    -- concat rendered rows
    results[#results + 1] = ""
    return table.concat(results, "\n")
end

-- return module
return text
