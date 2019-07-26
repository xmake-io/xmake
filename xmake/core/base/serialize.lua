
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

    -- serialize child items
    local childlevel = level + 1
    local serialized = {}
    local numidxcount = 0
    local isarr = true
    local maxn = 0
    for k, v in pairs(object) do
        if type(k) == "number" then
            -- only checks when it may be an array
            if isarr then
                numidxcount = numidxcount + 1
                if k < 1 or not math.isint(k) then
                    isarr = false
                elseif k > maxn then
                    maxn = k
                end
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
        indent = string.rep(opt.indent, level)
    end

    -- make head
    local headstr = opt.indent and ("{\n" .. indent .. opt.indent)  or "{"

    -- make tail
    local tailstr
    if opt.indent then
        tailstr = "\n" .. indent .. "}"
    else
        tailstr = "}"
    end

    -- make body
    local bodystrs = {}
    if isarr then
        for i = 1, maxn do
            bodystrs[i] = serialized[i] or "nil"
        end
    else
        local con = opt.indent and " = " or "="
        for k, v in pairs(serialized) do
            if type(k) == "string" then
                if not k:match("^[%a_][%w_]*$") then
                    k = string.format("[%q]", k)
                end
            else -- type(k) == "number"
                local nval, err = serialize._makenumber(k, opt, childlevel)
                if err ~= nil then
                    return nil, err
                end
                k = string.format("[%s]", nval)
            end
            table.insert(bodystrs, k .. con .. v)
        end
    end

    if #bodystrs == 0 then
        return opt.indent and "{ }" or "{}"
    end
    return headstr .. table.concat(bodystrs, opt.indent and (",\n" .. indent .. opt.indent) or ",") .. tailstr
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
    if opt == true then
        opt = { strip = true, binary = false, indent = false }
    elseif opt == false or opt == nil then
        opt = { strip = false, binary = false, indent = true }
    end

    -- init indent, from nil, boolean, number or string to false or string
    if not opt.indent then
        -- no indent
        opt.indent = false
    elseif type(opt.indent) == "boolean" then -- true
        -- 4 spaces
        opt.indent = "    "
    elseif type(opt.indent) == "number" then
        if opt.indent < 0 then
            opt.indent = false
        elseif opt.indent > 20 then
            return nil, "invalid opt.indent, too large"
        else
            -- opt.indent spaces
            opt.indent = string.rep(" ", opt.indent)
        end
    elseif type(opt.indent) == "string" then
        -- only whitespaces allowed
        if not opt.indent:match("^%s+$") then
            return nil, "invalid opt.indent, only whitespaces are accepted"
        end
    else
        return nil, "invalid opt.indent, should be boolean, number or string"
    end

    -- make string
    local ok, result, errors = pcall(serialize._make, object, opt, 0)
    if not ok then
        if result:find("stack overflow", 1, true) then
            errors = "cannot serialize: reference loop found"
        else
            errors = "cannot serialize: " .. result
        end
    end

    -- ok?
    if errors ~= nil then
        return nil, errors
    end

    if not opt.binary then
        return result
    end

    -- binary mode
    local func, lerr = loadstring("return " .. result)
    if lerr ~= nil then
        return nil, lerr
    end

    local dump, derr = serialize._dump(func, true)
    if derr ~= nil then
        return nil, derr
    end

    -- return shorter representation
    return (#dump < #result) and dump or result
end

-- load table from string in table
function serialize._load(str)

    -- load table as script
    local result = nil
    local binary = str:startswith("\27LJ")
    if not binary then
        str = "return " .. str
    end

    -- load string
    local script, errors = loadstring(str, "=(deserializing data)")
    if script then
        -- load object
        local ok, object = pcall(script)
        if ok then
            result = object
        else
            -- error
            errors = tostring(object)
        end
    end

    if errors then
        local data
        if binary then
            data = "<binary data>"
        elseif #str > 30 then
            data = string.format("%q... ", str:sub(8, 27))
        else
            data = string.format("%q", str:sub(8))
        end
        -- error
        return nil, string.format("cannot deserialize %s: %s", data, errors)
    end

    return result
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
    if errors ~= nil then
        return nil, errors
    end
    return result
end

-- return module: serialize
return serialize
