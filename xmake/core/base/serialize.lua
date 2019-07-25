
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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      OpportunityLiu
-- @file        serialize.lua
--

-- define module: serialize
local serialize = serialize or {}

-- load modules
local math      = require("base/math")

-- save original interfaces
serialize._dump = serialize._dump or string._dump or string.dump

function serialize._makenumber(num, opt, level)
    if math.isnan(num) then
        return "math.nan"
    end
    local inf = math.isinf(num)
    if inf == 1 then
        return "math.huge"
    elseif inf == -1 then
        return "-math.huge"
    end
    return tostring(num)
end

function serialize._makestring(str, opt, level)
    return string.format("%q", str)
end

function serialize._makekeyword(val, opt, level)
    return tostring(val)
end

function serialize._maketable(object, opt, level)

    local childlevel = level + 1

    -- serialize child items
    local serialized = {}
    local numidxcount = 0
    local isarr = true
    local maxn = 0
    for k, v in pairs(object) do
        if type(k) == "number" then
            numidxcount = numidxcount + 1
            if k < 1 or not math.isint(k) then
                isarr = false
            elseif k > maxn then
                maxn = k
            end
        elseif type(k) == "string" then
            isarr = false
        else
            return nil, string.format("cannot serialize table with key of %s: <%s>", type(k), k)
        end
        local sval, err = serialize._make(v, opt, childlevel)
        if err ~= nil then
            return nil, err
        end
        serialized[k] = sval
    end

    -- too sparse
    if numidxcount * 2 < maxn then
        isarr = false
    end

    -- make indent
    local indent = ""
    if opt.indent then
        indent = string.rep("    ", level)
    end

    -- make head
    local headstr
    if opt.indent then
        headstr = (level > 0 and "\n" or "") .. indent .. "{\n"
    else
        headstr = "{"
    end
    -- make tail
    local tailstr
    if opt.indent then
        tailstr = "\n" .. indent .. "}"
    else
        tailstr = "}"
    end

    -- make body
    local s = {}
    if opt.indent then
        indent = indent .. "    "
    end

    if isarr then
        local nilval
        if maxn ~= numidxcount then
            nilval = indent .. "nil"
        end
        for i = 1, maxn do
            local val = serialized[i]
            if val == nil then
                s[i] = nilval
            else
                s[i] = indent .. val
            end
        end
    else
        local con = opt.indent and " = " or "="
        for k, v in pairs(serialized) do
            if type(k) == "string" and not k:match("^[%a_][%w_]*$") then
                k = string.format("[%q]", k)
            elseif type(k) == "number" then
                local nval, err = serialize._makenumber(v, opt, childlevel)
                if err ~= nil then
                    return nil, err
                end
                k = string.format("[%s]", nval)
            end
            table.insert(s, indent .. k .. con .. v)
        end
    end
    return headstr .. table.concat(s, opt.indent and ",\n" or ",") .. tailstr
end

function serialize._makefunction(func, opt, level)
    local ok, funccode = pcall(serialize._dump, func, opt.strip)
    if not ok then
        return nil, string.format("%s: <%s>", funccode, func)
    end
    local chunkname = nil
    local sep = ","
    if opt.strip then
        chunkname = "\"=(deserialized code)\""
    end
    if opt.indent then
        sep = ", "
    end
    if chunkname then
        return string.format("loadstring(%q%s%s)", funccode, sep, chunkname)
    else
        return string.format("loadstring(%q)", funccode)
    end
end

-- make string with the level
function serialize._make(object, opt, level)

    -- call make* by type
    if type(object) == "string" then
        return serialize._makestring(object, opt, level)
    elseif type(object) == "boolean" or type(object) == "nil" then
        return serialize._makekeyword(object, opt, level)
    elseif type(object) == "number" then
        return serialize._makenumber(object, opt, level)
    elseif type(object) == "table" then
        return serialize._maketable(object, opt, level)
    elseif type(object) == "function" then
        return serialize._makefunction(object, opt, level)
    else
        return nil, string.format("cannot serialize %s: <%s>", type(object), object)
    end
end

-- serialize to string from the given object
--
-- @param opt           serialize options
--
-- @return              string, errors
--
function serialize.save(object, opt)

    -- init options
    opt = opt or {}

    -- make string
    local result, errors = serialize._make(object, opt, 0)

    -- ok?
    if errors ~= nil then
        return nil, errors
    end
    return result
end

-- load table from string in table
function serialize._load(str)

    -- load table as script
    local result = nil
    local script, errors = loadstring("return " .. str, str)
    if script then

        -- load object
        local ok, object = pcall(script)
        if ok then
            result = object
        elseif object then
            -- error
            errors = object
        else
            -- error
            errors = string.format("cannot deserialize string: %s", str)
        end
    end

    return result, errors
end

-- deserialize string to object
--
-- @param str           the serialized string
--
-- @return              object, errors
--
function serialize.load(str)

    -- check
    assert(str)

    -- load string
    local result, errors = serialize._load(str)

    -- ok?
    if errors ~= nil then
        return nil, errors
    end
    return result
end

-- return module: serialize
return serialize
