
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
-- @file        serialize.lua
--

-- define module: serialize
local serialize  = serialize or {}
local stub       = serialize._stub or {}
serialize._stub  = stub
serialize._dump  = serialize._dump or string._dump or string.dump

-- load modules
local math      = require("base/math")
local table     = require("base/table")
local hashset   = require("base/hashset")

-- reserved keywords in lua
function serialize._keywords()
    local keywords = serialize._KEYWORDS
    if not keywords then
        keywords  = hashset.of("and", "break", "do", "else", "elseif", "end", "false", "for", "function", "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while")
        serialize._KEYWORDS = keywords
    end
    return keywords
end

function serialize._makestring(str, opt)
    if string.find(str, "\\", 1, true) and not string.find(str, "[%c%]%\n]") then
        return string.format("[[%s]]", str)
    else
        return string.format("%q", str)
    end
end

function serialize._makedefault(val, opt)
    return tostring(val)
end

function serialize._maketable(obj, opt, level, pathsegs, reftab)

    level = level or 0
    reftab = reftab or {}
    pathsegs = pathsegs or {}
    reftab[obj] = table.copy(pathsegs)

    -- serialize child items
    local childlevel = level + 1
    local serialized = {}
    local numidxcount = 0
    local isarr = true
    local maxn = 0
    for k, v in pairs(obj) do
        -- check key
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

        -- serialize value
        local sval, err
        if type(v) == "table" then
            if reftab[v] then
                sval, err = serialize._makeref(reftab[v], opt)
            else
                table.insert(pathsegs, k)
                sval, err = serialize._maketable(v, opt, childlevel, pathsegs, reftab)
                table.remove(pathsegs)
            end
        else
            sval, err = serialize._make(v, opt)
        end
        if err ~= nil then
            return nil, err
        end
        serialized[k] = sval
    end

    -- empty table
    if isarr and numidxcount == 0 then
        return opt.indentstr and "{ }" or "{}"
    end

    -- too sparse
    if numidxcount * 2 < maxn then
        isarr = false
    end

    -- make body
    local bodystrs = {}
    if isarr then
        for i = 1, maxn do
            bodystrs[i] = serialized[i] or "nil"
        end
    else
        local dformat = opt.indentstr and "%s = %s" or "%s=%s"
        local sformat = opt.indentstr and "[%q] = %s" or "[%q]=%s"
        local nformat = opt.indentstr and "[%s] = %s" or "[%s]=%s"
        local keywords = serialize._keywords()
        for k, v in pairs(serialized) do
            local format
            -- serialize key
            if type(k) == "string" then
                if keywords:has(k) or not k:match("^[%a_][%w_]*$") then
                    format = sformat
                else
                    format = dformat
                end
            else -- type(k) == "number"
                format = nformat
            end
            -- concat k = v
            table.insert(bodystrs, string.format(format, k, v))
        end
    end

    -- make head and tail
    local headstr, bodysep, tailstr
    if opt.indentstr then
        local indent = "\n" .. string.rep(opt.indentstr, level)
        tailstr = indent .. "}"
        indent = indent .. opt.indentstr
        headstr = "{" .. indent
        bodysep = "," .. indent
    else
        headstr, bodysep, tailstr = "{", ",", "}"
    end

    -- concat together
    return headstr .. table.concat(bodystrs, bodysep) .. tailstr
end

function serialize._makefunction(func, opt)
    local ok, bytecode = pcall(serialize._dump, func, opt.strip)
    if not ok then
        return nil, string.format("%s: <%s>", bytecode, func)
    end
    return string.format("func%q", bytecode)
end

function serialize._resolvefunction(root, fenv, bytecode)
    -- check
    if type(bytecode) ~= "string" then
        return nil, string.format("invalid bytecode (string expected, got %s)", type(bytecode))
    end
    if not bytecode:startswith("\27LJ") then
        return nil, "cannot load incompatible bytecode"
    end

    -- resolve funccode
    local func, err = load(bytecode, "=(func)", "b", fenv)
    if err ~= nil then
        if err:startswith("(func): ") then
            err = err:sub(#"(func): " + 1)
        end
        return nil, err
    end

    -- try restore upvalues
    if fenv then
        for i = 1, math.huge do
            local upname = debug.getupvalue(func, i)
            if upname == nil or upname == "" then
                break
            end
            debug.setupvalue(func, i, fenv[upname])
        end
    end
    return func
end

function serialize._makeref(pathsegs, opt)

    -- root reference
    if pathsegs[1] == nil then
        return "ref()"
    end

    -- use replicas to avoid infinite generation of nested strings, e.g ref("\"xx\"") => ref("\\\"xx\\\"") => ..
    local pathrefs = {}
    for i, v in ipairs(pathsegs) do
        pathrefs[i] = serialize._make(v, opt)
    end

    return "ref(" .. table.concat(pathrefs, opt.indentstr and ", " or ",") .. ")"
end

function serialize._resolveref(root, fenv, ...)
    local pathsegs = table.pack("<root>", ...)
    local pos = root
    for i = 2, pathsegs.n do
        local pathseg = pathsegs[i]
        if type(pathseg) ~= "string" and type(pathseg) ~= "number" then
            return nil, "path segments should be string or number"
        end
        if type(pos) ~= "table" then
            local vpre = serialize._make(pathseg, {})
            local pathstr = table.concat(pathsegs, "/", 1, i)
            return nil, string.format("unable to resolve [%s] in %s, which is %s", vpre, pathstr, pos)
        end
        pos = pos[pathseg]
    end
    return pos
end

-- make string with the level
function serialize._make(obj, opt)

    -- call make* by type
    if type(obj) == "string" then
        return serialize._makestring(obj, opt)
    elseif type(obj) == "boolean" or type(obj) == "nil" or type(obj) == "number" then
        return serialize._makedefault(obj, opt)
    elseif type(obj) == "table" then
        return serialize._maketable(obj, opt)
    elseif type(obj) == "function" then
        return serialize._makefunction(obj, opt)
    else
        return nil, string.format("cannot serialize %s: <%s>", type(obj), obj)
    end
end

function serialize._generateindentstr(indent)

    -- init indent, from nil, boolean, number or string to false or string
    if not indent then
        -- no indent
        return nil
    elseif indent == true then
        -- 4 spaces
        return "    "
    elseif type(indent) == "number" then
        if indent < 0 then
            return nil
        elseif indent > 20 then
            return nil, "invalid opt.indent, too large"
        else
            -- indent spaces
            return string.rep(" ", indent)
        end
    elseif type(indent) == "string" then
        -- only whitespaces allowed
        if not (indent:trim() == "") then
            return nil, "invalid opt.indent, only whitespaces are accepted"
        end
        return indent
    else
        return nil, "invalid opt.indent, should be boolean, number or string"
    end
end

-- serialize to string from the given obj
--
-- @param opt           serialize options
--
-- @return              string, errors
--
function serialize.save(obj, opt)

    -- init options
    if opt == true then
        opt = { strip = true, binary = false, indent = false }
    elseif not opt then
        opt = {}
    end

    if opt.strip == nil then opt.strip = false end
    if opt.binary == nil then opt.binary = false end
    if opt.indent == nil then opt.indent = true end

    local indent, ierrors = serialize._generateindentstr(opt.indent)
    if ierrors then
        return nil, ierrors
    end
    opt.indentstr = indent

    -- make string
    local ok, result, errors = pcall(serialize._make, obj, opt)
    if not ok then
        errors = "cannot serialize: " .. result
    end

    -- ok?
    if errors ~= nil then
        return nil, errors
    end

    if not opt.binary then
        return result
    end

    -- binary mode
    local func, lerr = loadstring("return " .. result, "=")
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

-- init stub metatable
stub.isstub      = setmetatable({}, { __tostring = function() return "stub indentifier" end })
stub.__index     = stub

function stub:__call(root, fenv)
    return self.resolver(root, fenv, table.unpack(self.params, 1, self.params.n))
end

function stub:__tostring()
    local fparams = {}
    for i = 1, self.params.n do
        fparams[i] = serialize._make(self.params[i], {})
    end
    return string.format("%s(%s)", self.name, table.concat(fparams, ", "))
end

-- called by functions in deserialize environment
-- create a function (called stub) to finish deserialization
function serialize._createstub(name, resolver, env, ...)
    env.has_stub = true
    return setmetatable({ name = name, resolver = resolver, params = table.pack(...)}, stub)
end

-- after deserialization by load()
-- use this routine to call all stubs in deserialzed data
--
-- @param       obj   obj to search stubs
--              root     root obj
--              fenv     fenv of deserialzer caller
--              pathseg  path key for current item
function serialize._resolvestub(obj, root, fenv, pathseg)
    if type(obj) ~= "table" then
        return obj
    end

    if obj.isstub == stub.isstub then
        local ok, result_or_errors, errors = pcall(obj, root, fenv)
        if ok and errors == nil then
            return result_or_errors
        end

        -- resolve & concat path only if error occurs
        local pathsegs = {}
        local level = 1
        while true do
            if debug.getinfo(level, "f").func ~= serialize._resolvestub then
                break
            end
            local _, p = debug.getlocal(level, 4)
            table.insert(pathsegs, 1, p)
            level = level + 1
        end
        -- make error message
        local errmsg = (ok and errors) or result_or_errors or "unspecified error"
        return nil, string.format("failed to resolve stub '%s' at %s: %s", obj.name, table.concat(pathsegs, "/"), errmsg)
    end

    for k, v in pairs(obj) do
        local result, errors = serialize._resolvestub(v, root, fenv, k)
        if errors ~= nil then
            return nil, errors
        end
        obj[k] = result
    end
    return obj
end

-- create a env for deserialze load() call
function serialize._createenv()

    -- init env
    local env = { nan = math.nan, inf = math.huge }

    -- resolve reference
    function env.ref(...)
        -- load ref
        return serialize._createstub("ref", serialize._resolveref, env, ...)
    end

    -- load function
    function env.func(...)
        -- load func
        return serialize._createstub("func", serialize._resolvefunction, env, ...)
    end

    -- return new env
    return env
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
    local env = serialize._createenv()
    local script, errors = load(str, binary and "=(b)" or "=(t)", binary and "b" or "t", env)
    if script then
        -- load obj
        local ok, obj = pcall(script)
        if ok then
            result = obj
            if env.has_stub then
                local fenv = debug.getfenv(debug.getinfo(3, "f").func)
                result, errors = serialize._resolvestub(result, result, fenv, "<root>")
            end
        else
            -- error
            errors = tostring(obj)
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

-- deserialize string to obj
--
-- @param str           the serialized string
--
-- @return              obj, errors
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
