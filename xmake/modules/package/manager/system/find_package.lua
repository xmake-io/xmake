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
-- @file        find_package.lua
--

-- imports
import("core.language.language")
import("core.platform.platform")
import("private.core.base.is_cross")
import("lib.detect.check_cxsnippets")

-- get package items
function _get_package_items()
    local items = {}
    for _, apiname in ipairs(table.join(language.apis().values, language.apis().paths)) do
        if apiname:startswith("target.") then
            local valuename = apiname:split('.add_', {plain = true})[2]
            if valuename then
                table.insert(items, valuename)
            end
        end
    end
    return items
end

-- find package from system and compiler
-- @see https://github.com/xmake-io/xmake/issues/4596
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, package = <package instance>, includes = "", sourcekind = "[cc|cxx|mm|mxx]",
--              funcs = {"sigsetjmp", "sigsetjmp((void*)0, 0)"},
--              configs = {defines = "", links = "", cflags = ""}}
--
function main(name, opt)
    opt = opt or {}
    if is_cross(opt.plat, opt.arch) then
        return
    end

    local configs = opt.configs or {}
    local items = _get_package_items()
    local snippet_configs = {}
    for _, name in ipairs(items) do
        snippet_configs[name] = configs[name]
    end
    snippet_configs.links = snippet_configs.links or name

    local snippet_opt = {
        verbose = opt.verbose,
        target = opt.package,
        funcs = opt.funcs,
        sourcekind = opt.sourcekind,
        includes = opt.includes,
        configs = snippet_configs}

    local snippetname = "find_package/" .. name
    local snippets = opt.snippets or {[snippetname] = ""}
    if check_cxsnippets(snippets, snippet_opt) then
        local result = snippet_configs
        if not table.empty(result) then
            return result
        end
    end
end
