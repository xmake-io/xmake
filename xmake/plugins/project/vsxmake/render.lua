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
-- @author      OpportunityLiu
-- @file        render.lua
--

function _fill(opt, params)
    return function(match)
        local imp = match:match("^Import%((.+)%)$")
        if imp then
            local funcs = os.files(path.join(opt.templatedir, imp .. "(*)"))
            assert(#funcs == 1)
            local func = funcs[1]
            local args = path.filename(func):match("%((.+)%)$"):split(",")
            return _render(func, opt, args)
        end
        return opt.paramsprovider(match, params) or "<Not Provided>"
    end
end

function _cfill(opt, params)
    return function(match)
        local tmp = match:split(";", {strict = true, plain = true})
        assert(#tmp == 2 or #tmp == 3)

        local cond = tmp[1]
        local value1 = tmp[2]
        local value2 = ""
        local len = false

        if #tmp == 3 then
            value2 = tmp[3]
        end

        local ops = { "==", "~=", "<=", ">=", "<", ">", "=" }
        local op, k, v

        for _, o in ipairs(ops) do
            local i, j = cond:find(o, 1, true)
            if i ~= nil then
                op = o
                k = cond:sub(1, i - 1):trim()
                v = cond:sub(j + 1):trim()
                break
            end
        end

        assert(op and k and v)
        
        if k:startswith("#") then
            k = k:sub(2)
            len = true
        end

        local m = k:split(".", { plain = true })
        local p
        local old_target = opt.paramsprovider() or ""
        for i, item in ipairs(m) do
            if i == 1 then
                p = opt.paramsprovider(item, params)
                if item == "target" then
                    opt.paramsprovider(p)
                end
            else
                p = _expand(opt.paramsprovider({item}))
            end
        end

        if _cmp(p, v, op, len) then
            return value1
        end

        if old_target ~= opt.paramsprovider() then
            opt.paramsprovider(old_target)
        end

        return value2
    end
end

function _cmp(lhs, rhs, op, len)
    if len then
        lhs = #lhs
    end

    if type(lhs) == "number" then
        rhs = tonumber(rhs)
    end

    if op == "==" or op == "=" then
        return lhs == rhs
    end

    if op == "~=" then
        return lhs ~= rhs
    end

    if op == "<=" then
        return lhs <= rhs
    end

    if op == ">=" then
        return lhs >= rhs
    end

    if op == "<" then
        return lhs < rhs
    end

    if op == ">" then
        return lhs > rhs
    end

    raise("unknown operator '" .. op .. "'")
end

function _expand(params)
    local r = {""}
    for _, v in ipairs(params) do
        if type(v) == "string" then
            for i, p in ipairs(r) do
                r[i] = p .. "\0" .. v
            end
        else
            local newr = {}
            for _, c in ipairs(v) do
                local rcopy = {}
                for i, p in ipairs(r) do
                    rcopy[i] = p .. "\0" .. c
                end
                newr = table.join(newr, rcopy)
            end
            r = newr
        end
    end
    for i, p in ipairs(r) do
        r[i] = p:split("\0")
    end
    return r
end

local save_target

function _render(templatepath, opt, args)
    local template = io.readfile(templatepath)
    local params = _expand(opt.paramsprovider(args))
    local replaced = ""
    for _, v in ipairs(params) do
        local tmpl = template:gsub(opt.cpattern, _cfill(opt, v))
        replaced = replaced .. tmpl:gsub(opt.pattern, _fill(opt, v))
    end

    if save_target ~= opt.paramsprovider() then
        opt.paramsprovider(save_target)
    end

    return replaced
end

function main(templatepath, pattern, cpattern, paramsprovider)
    local opt = { pattern = pattern, cpattern = cpattern, paramsprovider = paramsprovider, templatedir = path.directory(templatepath) }
    save_target = paramsprovider() or ""
    return _render(templatepath, opt, {})
end
