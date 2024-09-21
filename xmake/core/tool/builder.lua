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
-- @file        builder.lua
--

-- define module
local builder = builder or {}

-- load modules
local io       = require("base/io")
local path     = require("base/path")
local utils    = require("base/utils")
local table    = require("base/table")
local string   = require("base/string")
local option   = require("base/option")
local hashset  = require("base/hashset")
local graph    = require("base/graph")
local tool     = require("tool/tool")
local config   = require("project/config")
local sandbox  = require("sandbox/sandbox")
local language = require("language/language")
local platform = require("platform/platform")

-- get the tool of builder
function builder:_tool()
    return self._TOOL
end

-- get the name flags
function builder:_nameflags()
    return self._NAMEFLAGS
end

-- get the target kind
function builder:_targetkind()
    return self._TARGETKIND
end

-- map flag implementation
function builder:_mapflag_impl(flag, flagkind, mapflags, auto_ignore_flags)

    -- attempt to map it directly
    local flag_mapped = mapflags[flag]
    if flag_mapped then
        return flag_mapped
    end

    -- find and replace it using pattern, maybe flag is table, e.g. {"-I", "/xxx"}
    if type(flag) == "string" then
        for k, v in pairs(mapflags) do
            local flag_mapped, count = flag:gsub("^" .. k .. "$", function (w) return v end)
            if flag_mapped and count ~= 0 then
                return #flag_mapped ~= 0 and flag_mapped
            end
        end
    end

    -- has this flag?
    if auto_ignore_flags == false or self:has_flags(flag, flagkind) then
        return flag
    else
        utils.warning("add_%s(\"%s\") is ignored, please pass `{force = true}` or call `set_policy(\"check.auto_ignore_flags\", false)` if you want to set it.", flagkind, os.args(flag))
    end
end

-- map flag
function builder:_mapflag(flag, flagkind, target)
    local mapflags = self:get("mapflags")
    local auto_map_flags = target and target.policy and target:policy("check.auto_map_flags")
    local auto_ignore_flags = target and target.policy and target:policy("check.auto_ignore_flags")
    if mapflags and (auto_map_flags ~= false) then
        return self:_mapflag_impl(flag, flagkind, mapflags, auto_ignore_flags)
    else
        if auto_ignore_flags == false or self:has_flags(flag, flagkind) then
            return flag
        else
            utils.warning("add_%s(\"%s\") is ignored, please pass `{force = true}` or call `set_policy(\"check.auto_ignore_flags\", false)` if you want to set it.", flagkind, flag)
        end
    end
end

-- map flags
function builder:_mapflags(flags, flagkind, target)
    local results = {}
    local mapflags = self:get("mapflags")
    local auto_map_flags = target and target.policy and target:policy("check.auto_map_flags")
    local auto_ignore_flags = target and target.policy and target:policy("check.auto_ignore_flags")
    flags = table.wrap(flags)
    if mapflags and (auto_map_flags ~= false) then
        for _, flag in pairs(flags) do
            local flag_mapped = self:_mapflag_impl(flag, flagkind, mapflags, auto_ignore_flags)
            if flag_mapped then
                table.insert(results, flag_mapped)
            end
        end
    else
        for _, flag in pairs(flags) do
            if auto_ignore_flags == false or self:has_flags(flag, flagkind) then
                table.insert(results, flag)
            else
                utils.warning("add_%s(\"%s\") is ignored, please pass `{force = true}` or call `set_policy(\"check.auto_ignore_flags\", false)` if you want to set it.", flagkind, flag)
            end
        end
    end
    return results
end

-- get the flag kinds
function builder:_flagkinds()
    return self._FLAGKINDS
end

-- get the extra configuration from value
function builder:_extraconf(extras, value)
    local extra = extras
    if extra then
        if type(value) == "table" then
            extra = extra[table.concat(value, "_")]
        else
            extra = extra[value]
        end
    end
    return extra
end

-- inherit flags (only for public/interface) from target deps
--
-- e.g.
-- add_cflags("", {public = true})
-- add_cflags("", {interface = true})
--
function builder:_inherit_flags_from_targetdeps(flags, target)
    local orderdeps = target:orderdeps({inherit = true})
    local total = #orderdeps
    for idx, _ in ipairs(orderdeps) do
        local dep = orderdeps[total + 1 - idx]
        for _, flagkind in ipairs(self:_flagkinds()) do
            self:_add_flags_from_flagkind(flags, dep, flagkind, {interface = true})
        end
    end
end

-- add flags from the flagkind
function builder:_add_flags_from_flagkind(flags, target, flagkind, opt)
    local targetflags = target:get(flagkind, opt)
    local extraconf   = target:extraconf(flagkind)
    for _, flag in ipairs(table.wrap(targetflags)) do
        -- does this flag belong to this tool?
        -- @see https://github.com/xmake-io/xmake/issues/3022
        --
        -- e.g.
        -- for all: add_cxxflags("-g")
        -- only for clang: add_cxxflags("clang::-stdlib=libc++")
        -- only for clang and multiple flags: add_cxxflags("-stdlib=libc++", "-DFOO", {tools = "clang"})
        --
        local for_this_tool = true
        local flagconf = extraconf and extraconf[flag]
        if type(flag) == "string" and flag:find("::", 1, true) then
            for_this_tool = false
            local splitinfo = flag:split("::", {plain = true})
            local toolname = splitinfo[1]
            if toolname == self:name() then
                flag = splitinfo[2]
                for_this_tool = true
            end
        elseif flagconf and flagconf.tools then
            for_this_tool = table.contains(table.wrap(flagconf.tools), self:name())
        end

        if for_this_tool then
            if extraconf then
                -- @note we need join the single flag with shallow mode, aboid expand table values
                -- e.g. add_cflags({"-I", "/tmp/xxx foo"}, {force = true, expand = false})
                if flagconf and flagconf.force then
                    table.shallow_join2(flags, flag)
                else
                    table.shallow_join2(flags, self:_mapflag(flag, flagkind, target))
                end
            else
                table.shallow_join2(flags, self:_mapflag(flag, flagkind, target))
            end
        end
    end
end

-- add flags from the configure
function builder:_add_flags_from_config(flags)
    for _, flagkind in ipairs(self:_flagkinds()) do
        local values = config.get(flagkind)
        if values then
            table.join2(flags, os.argv(values))
        end
    end
end

-- add flags from the target options
function builder:_add_flags_from_targetopts(flags, target)
    for _, flagkind in ipairs(self:_flagkinds()) do
        local result = target:get_from(flagkind, "option::*")
        if result then
            for _, values in ipairs(table.wrap(result)) do
                table.join2(flags, self:_mapflags(values, flagkind, target))
            end
        end
    end
end

-- add flags from the target packages
function builder:_add_flags_from_targetpkgs(flags, target)
    local kind = self:kind()
    for _, flagkind in ipairs(self:_flagkinds()) do
        -- attempt to add special lanugage flags from package first, e.g. gcldflags, dcarflags
        -- @see https://github.com/xmake-io/xmake-repo/issues/5255
        local result
        if kind:endswith("ld") or kind:endswith("sh") then
            result = target:get_from(kind .. "flags", "package::*")
        end
        if not result then
            result = target:get_from(flagkind, "package::*")
        end
        if result then
            for _, values in ipairs(table.wrap(result)) do
                table.join2(flags, self:_mapflags(values, flagkind, target))
            end
        end
    end
end

-- add flags from the target
function builder:_add_flags_from_target(flags, target)

    -- no target?
    if not target then
        return
    end

    -- only for target and option
    local target_type = target:type()
    if target_type ~= "target" and target_type ~= "option" then
        return
    end

    -- init cache
    self._TARGETFLAGS = self._TARGETFLAGS or {}
    local cache = self._TARGETFLAGS

    -- get flags from cache first
    local key = target:cachekey()
    local targetflags = cache[key]
    if not targetflags then

        -- add flags from language
        targetflags = {}
        self:_add_flags_from_language(targetflags, {target = target})

        -- add flags for the target
        if target_type == "target" then

            -- add flags from options
            self:_add_flags_from_targetopts(targetflags, target)

            -- add flags from packages
            self:_add_flags_from_targetpkgs(targetflags, target)

            -- inherit flags (public/interface) from all dependent targets
            self:_inherit_flags_from_targetdeps(targetflags, target)
        end

        -- add the target flags
        for _, flagkind in ipairs(self:_flagkinds()) do
            self:_add_flags_from_flagkind(targetflags, target, flagkind)
        end
        cache[key] = targetflags
    end
    table.join2(flags, targetflags)
end

-- add flags from the argument option
function builder:_add_flags_from_argument(flags, target, args)

    -- add flags from the flag kinds (cxflags, ..)
    for _, flagkind in ipairs(self:_flagkinds()) do
        table.join2(flags, self:_mapflags(args[flagkind], flagkind, target))
        local original_flags = (args.force or {})[flagkind]
        if original_flags then
            table.join2(flags, original_flags)
        end
    end

    -- add flags (named) from the language
    self:_add_flags_from_language(flags, {linkorders = args.linkorders, linkgroups = args.linkgroups, getters = {
        target = function (name)
            -- we need also to get extra from arguments
            -- @see https://github.com/xmake-io/xmake/issues/4274
            --
            -- e.g.
            -- package/add_linkgroups("xxx", {group = true})
            -- {linkgroups = , extras = {
            --     linkgroups = {z = {group = true}}
            -- }}
            local values = args[name]
            local extras = args.extras and args.extras[name]
            return values, extras
        end,
        toolchain = function (name)
            if target and target.toolconfig then
                return target:toolconfig(name)
            end
            local plat, arch
            if target and target.plat then
                plat = target:plat()
            end
            if target and target.arch then
                arch = target:arch()
            end
            return platform.toolconfig(name, plat, arch)
        end}})
end

-- add items from getter
function builder:_add_items_from_getter(items, name, opt)
    local values, extras = opt.getter(name)
    if values then
        table.insert(items, {
            name = name,
            values = table.wrap(values),
            check = opt.check,
            multival = opt.multival,
            mapper = opt.mapper,
            extras = extras})
    end
end

-- add items from config
function builder:_add_items_from_config(items, name, opt)
    local values = config.get(name)
    if values and name:endswith("dirs") then
        values = path.splitenv(values)
    end
    if values then
        table.insert(items, {
            name = name,
            values = table.wrap(values),
            check = opt.check,
            multival = opt.multival,
            mapper = opt.mapper})
    end
end

-- add items from toolchain
function builder:_add_items_from_toolchain(items, name, opt)
    local values
    local target = opt.target
    if target and target:type() == "target" then
        values = target:toolconfig(name)
    else
        values = platform.toolconfig(name)
    end
    if values then
        table.insert(items, {
            name = name,
            values = table.wrap(values),
            check = opt.check,
            multival = opt.multival,
            mapper = opt.mapper})
    end
end

-- add items from option
function builder:_add_items_from_option(items, name, opt)
    local values
    local target = opt.target
    if target then
        values = target:get(name)
    end
    if values then
        table.insert(items, {
            name = name,
            values = table.wrap(values),
            check = opt.check,
            multival = opt.multival,
            mapper = opt.mapper})
    end
end

-- add items from target
function builder:_add_items_from_target(items, name, opt)
    local target = opt.target
    if target then
        local result, sources = target:get_from(name, "*")
        if result then
            for idx, values in ipairs(result) do
                local source = sources[idx]
                local extras = target:extraconf_from(name, source)
                values = table.wrap(values)
                if values and #values > 0 then
                    table.insert(items, {
                        name = name,
                        values = values,
                        extras = extras,
                        check = opt.check,
                        multival = opt.multival,
                        mapper = opt.mapper})
                end
            end
        end
    end
end

-- add flags from the language
function builder:_add_flags_from_language(flags, opt)
    opt = opt or {}

    -- get order named items
    local items = {}
    local target = opt.target
    for _, flaginfo in ipairs(self:_nameflags()) do

        -- get flag info
        local flagscope     = flaginfo[1]
        local flagname      = flaginfo[2]
        local checkstate    = flaginfo[3]
        if checkstate then
            local auto_ignore_flags = target and target.policy and target:policy("check.auto_ignore_flags")
            if auto_ignore_flags == false then
                checkstate = false
            end
        end

        -- get api name of tool
        local apiname  = flagname:gsub("^nf_", "")

        -- use multiple values mapper if be defined in tool module
        local multival = false
        if apiname:endswith("s") then
            if self:_tool()["nf_" .. apiname] then
                multival = true
            else
                apiname = apiname:sub(1, #apiname - 1)
            end
        end

        -- map named flags to real flags
        local mapper = self:_tool()["nf_" .. apiname]
        if mapper then
            local opt_ = {target = target, check = checkstate, multival = multival, mapper = mapper}
            if opt.getters then
                local getter = opt.getters[flagscope]
                if getter then
                    opt_.getter = getter
                    self:_add_items_from_getter(items, flagname, opt_)
                end
            elseif flagscope == "target" and target and target:type() == "target" then
                self:_add_items_from_target(items, flagname, opt_)
            elseif flagscope == "target" and target and target:type() == "option" then
                self:_add_items_from_option(items, flagname, opt_)
            elseif flagscope == "config" then
                self:_add_items_from_config(items, flagname, opt_)
            elseif flagscope == "toolchain" then
                self:_add_items_from_toolchain(items, flagname, opt_)
            end
        end
    end

    -- sort links
    local kind = self:kind()
    if kind == "ld" or kind == "sh" then
        local linkorders = table.wrap(opt.linkorders)
        local linkgroups = table.wrap(opt.linkgroups)
        if target and target:type() == "target" then
            local values = target:get_from("linkorders", "*")
            if values then
                for _, value in ipairs(values) do
                    table.join2(linkorders, value)
                end
            end
            values = target:get_from("linkgroups", "*")
            if values then
                for _, value in ipairs(values) do
                    table.join2(linkgroups, value)
                end
            end
        end
        if #linkorders > 0 or #linkgroups > 0 then
            self:_sort_links_of_items(items, {linkorders = linkorders, linkgroups = linkgroups})
        end
    end

    -- get flags from the items
    for _, item in ipairs(items) do
        local check = item.check
        local mapper = item.mapper
        local extras = item.extras
        if item.multival then
            local extra = self:_extraconf(extras, item.values)
            local results = mapper(self:_tool(), item.values, {target = target, targetkind = self:_targetkind(), extra = extra})
            for _, flag in ipairs(table.wrap(results)) do
                if flag and flag ~= "" and (not check or self:has_flags(flag)) then
                    table.insert(flags, flag)
                end
            end
        else
            for _, flagvalue in ipairs(item.values) do
                local extra = self:_extraconf(extras, flagvalue)
                local flag = mapper(self:_tool(), flagvalue, {target = target, targetkind = self:_targetkind(), extra = extra})
                if flag and flag ~= "" and (not check or self:has_flags(flag)) then
                    table.insert(flags, flag)
                end
            end
        end
    end
end

-- sort links of items
function builder:_sort_links_of_items(items, opt)
    opt = opt or {}
    local sortlinks = false
    local makegroups = false
    local linkorders = table.wrap(opt.linkorders)
    if #linkorders > 0 then
        sortlinks = true
    end
    local linkgroups = table.wrap(opt.linkgroups)
    local linkgroups_set = hashset.new()
    if #linkgroups > 0 then
        makegroups = true
        for _, linkgroup in ipairs(linkgroups) do
            for _, link in ipairs(linkgroup) do
                linkgroups_set:insert(link)
            end
        end
    end

    -- get all links
    local links = {}
    local linkgroups_map = {}
    local extras_map = {}
    local link_mapper
    local framework_mapper
    local linkgroup_mapper
    if sortlinks or makegroups then
        local linkitems = {}
        table.remove_if(items, function (_, item)
            local name = item.name
            local removed = false
            if name == "links" or name == "syslinks" then
                link_mapper = item.mapper
                removed = true
                table.insert(linkitems, item)
            elseif name == "frameworks" then
                framework_mapper = item.mapper
                removed = true
                table.insert(linkitems, item)
            elseif name == "linkgroups" then
                linkgroup_mapper = item.mapper
                removed = true
                table.insert(linkitems, item)
            end
            return removed
        end)

        -- @note table.remove_if will traverse backwards,
        -- we need to fix the initial link order first to make sure the syslinks are in the correct order
        linkitems = table.reverse(linkitems)
        for _, item in ipairs(linkitems) do
            local name = item.name
            for _, value in ipairs(item.values) do
                if name == "links" or name == "syslinks" then
                    if not linkgroups_set:has(value) then
                        table.insert(links, value)
                    end
                elseif name == "frameworks" then
                    table.insert(links, "framework::" .. value)
                elseif name == "linkgroups" then
                    local extras = item.extras
                    local extra = self:_extraconf(extras, value)
                    local key = extra and extra.name or tostring(value)
                    table.insert(links, "linkgroup::" .. key)
                    linkgroups_map[key] = value
                    extras_map[key] = extras
                end
            end
        end

        links = table.reverse_unique(links)
    end

    -- sort sublinks
    if sortlinks then
        local gh = graph.new(true)
        local from
        local original_deps = {}
        for _, link in ipairs(links) do
            local to = link
            if from and to then
                original_deps[from] = to
            end
            from = to
        end
        -- we need remove cycle in original links
        -- e.g.
        --
        -- case1:
        -- original_deps: a -> b -> c -> d -> e
        -- new deps: e -> b
        -- graph: a -> b -> c -> d    e  (remove d -> e, add d -> nil)
        --            /|\             |
        --              --------------
        --
        -- case2:
        -- original_deps: a -> b -> c -> d -> e
        -- new deps: b -> a
        --
        --         ---------
        --        |        \|/
        -- graph: a    b -> c -> d -> e  (remove a -> b, add a -> c)
        --       /|\   |
        --         ----
        --
        local function remove_cycle_in_original_deps(f, t)
            local k
            local v = t
            while v ~= f do
                k = v
                v = original_deps[v]
                if v == nil then
                    break
                end
            end
            if v == f and k ~= nil then
                -- break the original from node, link to next node
                -- e.g.
                -- case1: d -x-> e, d -> nil, k: d, f: e
                -- case2: a -x-> b, a -> c, k: a, f: b
                original_deps[k] = original_deps[f]
            end
        end
        local links_set = hashset.from(links)
        for _, linkorder in ipairs(linkorders) do
            local from
            for _, link in ipairs(linkorder) do
                if links_set:has(link) then
                    local to = link
                    if from and to then
                        remove_cycle_in_original_deps(from, to)
                        gh:add_edge(from, to)
                    end
                    from = to
                end
            end
        end
        for k, v in pairs(original_deps) do
            gh:add_edge(k, v)
        end
        if not gh:empty() then
            local cycle = gh:find_cycle()
            if cycle then
                utils.warning("cycle links found in add_linkorders(): %s", table.concat(cycle, " -> "))
            end
            links = gh:topological_sort()
        end
    end

    -- re-generate links to items list
    if sortlinks or makegroups then
        for _, link in ipairs(links) do
            if link:startswith("framework::") then
                link = link:sub(12)
                table.insert(items, {name = "frameworks", values = table.wrap(link), check = false, multival = false, mapper = framework_mapper})
            elseif link:startswith("linkgroup::") then
                local key = link:sub(12)
                local values = linkgroups_map[key]
                local extras = extras_map[key]
                table.insert(items, {name = "linkgroups", values = table.wrap(values), extras = extras, check = false, multival = false, mapper = linkgroup_mapper})
            else
                table.insert(items, {name = "links", values = table.wrap(link), check = false, multival = false, mapper = link_mapper})
            end
        end
    end
end

-- preprocess flags
function builder:_preprocess_flags(flags)

    -- remove repeat by right direction, because we need to consider links/deps order
    -- @note https://github.com/xmake-io/xmake/issues/1240
    local unique = {}
    local count = #flags
    if count > 1 then
        local flags_new = {}
        for idx = count, 1, -1 do
            local flag = flags[idx]
            local flagkey = type(flag) == "table" and table.concat(flag, "") or flag
            if flag and not unique[flagkey] then
                table.insert(flags_new, flag)
                unique[flagkey] = true
            end
        end
        flags = flags_new
        count = #flags_new
    end

    -- remove repeat first and split flags group, e.g. "-I /xxx" => {"-I", "/xxx"}
    local results = {}
    if count > 0 then
        for idx = count, 1, -1 do
            local flag = flags[idx]
            if type(flag) == "string" then
                flag = flag:trim()
                if #flag > 0 then
                    if flag:find(" ", 1, true) then
                        table.join2(results, os.argv(flag, {splitonly = true}))
                    else
                        table.insert(results, flag)
                    end
                end
            else
                -- may be a table group? e.g. {"-I", "/xxx"}
                if #flag > 0 then
                    table.wrap_unlock(flag)
                    table.join2(results, flag)
                end
            end
        end
    end
    return results
end

-- get the target
function builder:target()
    return self._TARGET
end

-- get tool name
function builder:name()
    return self:_tool():name()
end

-- get tool kind
function builder:kind()
    return self:_tool():kind()
end

-- get tool program
function builder:program()
    return self:_tool():program()
end

-- get toolchain of this tool
function builder:toolchain()
    return self:_tool():toolchain()
end

-- get the run environments
function builder:runenvs()
    return self:_tool():runenvs()
end

-- get properties of the tool
function builder:get(name)
    return self:_tool():get(name)
end

-- has flags?
function builder:has_flags(flags, flagkind, opt)
    return self:_tool():has_flags(flags, flagkind, opt)
end

-- map flags from name and values, e.g. linkdirs, links, defines
function builder:map_flags(name, values, opt)
    local flags  = {}
    local mapper = self:_tool()["nf_" .. name]
    local multival = false
    if name:endswith("s") then
        multival = true
    elseif not mapper then
        mapper = self:_tool()["nf_" .. name .. "s"]
        if mapper then
            multival = true
        end
    end
    if mapper then
        opt = opt or {}
        if multival then
            local extra = self:_extraconf(opt.extras, values)
            local results = mapper(self:_tool(), values, {target = opt.target, targetkind = opt.targetkind, extra = extra})
            for _, flag in ipairs(table.wrap(results)) do
                if flag and flag ~= "" and (not opt.check or self:has_flags(flag)) then
                    table.insert(flags, flag)
                end
            end
        else
            for _, value in ipairs(table.wrap(values)) do
                local extra = self:_extraconf(opt.extras, value)
                local flag = mapper(self:_tool(), value, {target = opt.target, targetkind = opt.targetkind, extra = extra})
                if flag and flag ~= "" and (not opt.check or self:has_flags(flag)) then
                    table.join2(flags, flag)
                end
            end
        end
    end
    if #flags > 0 then
        return flags
    end
end

-- return module
return builder
