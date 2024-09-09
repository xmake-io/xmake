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

-- imports
import("lib.detect.find_file")

function _fill(opt, params)
    return function(match)
        local imp = match:match("^Import%((.+)%)$")
        if imp then
            local func = find_file(imp .. "(*)", opt.templatedir)
            assert(func)
            local args = path.filename(func):match("%((.+)%)$"):split(",", {plain = true})
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

        if #tmp == 3 then
            value2 = tmp[3]
        end
        tmp = cond:split("=", {plain = true})
        assert(#tmp == 2)

        local k = tmp[1]:trim()
        local v = tmp[2]:trim()
        if opt.paramsprovider(k, params) == v then
            return value1
        end
        return value2
    end
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
                for _, p in ipairs(r) do
                    table.insert(newr, p .. "\0" .. c)
                end
            end
            r = newr
        end
    end
    for i, p in ipairs(r) do
        r[i] = p:split("\0")
    end
    return r
end

function _render(templatepath, opt, args)
    local template = io.readfile(templatepath)
    local params = _expand(opt.paramsprovider(args))
    local replaced = ""
    for _, v in ipairs(params) do
        local tmpl = template:gsub(opt.cpattern, _cfill(opt, v))
        replaced = replaced .. tmpl:gsub(opt.pattern, _fill(opt, v))
    end
    return replaced
end

function main(templatepath, pattern, cpattern, paramsprovider)
    local opt = {
        pattern = pattern,
        cpattern = cpattern,
        paramsprovider = paramsprovider,
        templatedir = path.directory(templatepath)
    }
    return _render(templatepath, opt, {})
end

