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
-- @author      ruki
-- @file        try.lua
--

-- load modules
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local option    = require("base/option")

-- define module
local sandbox_try = sandbox_try or {}

-- traceback
function sandbox_try._traceback(errors)

    -- no diagnosis info?
    if not option.get("diagnosis") then
        if errors then
            -- remove the prefix info
            local _, pos = errors:find(":%d+: ")
            if pos then
                errors = errors:sub(pos + 1)
            end
        end
        return errors
    end

    -- traceback exists?
    if errors and errors:find("stack traceback:", 1, true) then
        return errors
    end

    -- init results
    local results = ""
    if errors then
        results = errors .. "\n"
    end
    results = results .. "stack traceback:\n"

    -- make results
    local level = 2
    while true do

        -- get debug info
        local info = debug.getinfo(level, "Sln")

        -- end?
        if not info or (info.name and info.name == "xpcall") then
            break
        end

        -- function?
        if info.what == "C" then
            results = results .. string.format("    [C]: in function '%s'\n", info.name)
        elseif info.name then
            results = results .. string.format("    [%s:%d]: in function '%s'\n", info.short_src, info.currentline, info.name)
        elseif info.what == "main" then
            results = results .. string.format("    [%s:%d]: in main chunk\n", info.short_src, info.currentline)
            break
        else
            results = results .. string.format("    [%s:%d]:\n", info.short_src, info.currentline)
        end

        -- next
        level = level + 1
    end

    -- ok?
    return results
end

-- local ok = try
-- {
--   function ()
--      raise("errors")
--      raise({errors = "xxx", xxx = "", yyy = ""})
--      return true
--   end,
--   catch
--   {
--      function (errors)
--          print(errors)
--          if errors then
--              print(errors.xxx)
--          end
--      end
--   },
--   finally
--   {
--      function (ok, result_or_errors)
--      end
--   }
-- }
function sandbox_try.try(block)

    -- get the try function
    local try = block[1]
    assert(try)

    -- get catch and finally functions
    local funcs = table.join(block[2] or {}, block[3] or {})

    -- try to call it
    local results = table.pack(utils.trycall(try, sandbox_try._traceback))
    local ok = results[1]
    if not ok then

        -- run the catch function
        if funcs and funcs.catch then
            funcs.catch(results[2])
        end
    end

    -- run the finally function
    if funcs and funcs.finally then
        funcs.finally(ok, table.unpack(results, 2, results.n))
    end

    -- ok?
    if ok then
        return table.unpack(results, 2, results.n)
    end
end

-- return module
return sandbox_try.try
