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
-- @file        render.lua
--

function _fill(opt, parmas)
    return function(match)
        local imp = match:match("^Import%((.+)%)$")
        if imp then
            local func, overload = os.files(path.join(opt.templatedir, imp .. "(*)"))
            assert(overload == 1)
            func = func[1]
            local args = path.filename(func):match("%((.+)%)$"):split(",")
            return _render(func, opt, args)
        end
        return opt.paramsprovider(match, parmas) or "<Not Provided>"
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
                local rcopy = {}
                for i, p in ipairs(r) do
                    rcopy[i] = p .. "\0" .. c
                end
               newr= table.join(newr, rcopy)
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
        replaced = replaced .. template:gsub(opt.pattern, _fill(opt, v))
    end
    return replaced
end

function main(templatepath, pattern, paramsprovider)
    local opt = { pattern = pattern, paramsprovider = paramsprovider, templatedir = path.directory(templatepath) }
    return _render(templatepath, opt, {})
end