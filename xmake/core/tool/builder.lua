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

-- inherit flags (only for public/interface) from target deps
--
-- e.g.
-- add_cflags("", {public = true})
-- add_cflags("", {interface = true})
--
function builder:_inherit_flags_from_targetdeps(flags, target)
    local orderdeps = target:orderdeps()
    local total = #orderdeps
    for idx, _ in ipairs(orderdeps) do
        local dep = orderdeps[total + 1 - idx]
        local depinherit = target:extraconf("deps", dep:name(), "inherit")
        if depinherit == nil or depinherit then
            for _, flagkind in ipairs(self:_flagkinds()) do
                self:_add_flags_from_flagkind(flags, dep, flagkind, {interface = true})
            end
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
    for _, opt in ipairs(target:orderopts()) do
        for _, flagkind in ipairs(self:_flagkinds()) do
            self:_add_flags_from_flagkind(flags, opt, flagkind)
        end
    end
end

-- add flags from the target packages
function builder:_add_flags_from_targetpkgs(flags, target)
    for _, pkg in ipairs(target:orderpkgs()) do
        for _, flagkind in ipairs(self:_flagkinds()) do
            table.join2(flags, self:_mapflags(pkg:get(flagkind), flagkind, target))
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
        self:_add_flags_from_language(targetflags, target)

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
    self:_add_flags_from_language(flags, nil, {
        target = function (name) return args[name] end,
        toolchain = function (name)
            local plat, arch
            if target and target.plat then
                plat = target:plat()
            end
            if target and target.arch then
                arch = target:arch()
            end
            return platform.toolconfig(name, plat, arch)
        end})
end

-- add flags from the language
function builder:_add_flags_from_language(flags, target, getters)

    -- init getters
    --
    -- e.g.
    --
    -- target.linkdirs => flags = getters("target")("linkdirs")
    --
    local getters = getters or
    {
        config      =   function (name)
                            local values = config.get(name)
                            if values and name:endswith("dirs") then
                                values = path.splitenv(values)
                            end
                            return values
                        end
    ,   toolchain   =   function (name)
                            if target and target:type() == "target" then
                                return target:toolconfig(name)
                            else
                                return platform.toolconfig(name)
                            end
                        end
    ,   target      =   function (name)
                            local results = {}
                            if target:type() == "target" then

                                -- get flagvalues of target with given flagname
                                table.join2(results, target:get(name))

                                -- get flagvalues of the attached options and packages
                                table.join2(results, target:get_from_opts(name))
                                table.join2(results, target:get_from_pkgs(name))

                                -- get flagvalues (public or interface) of all dependent targets (contain packages/options)
                                table.join2(results, target:get_from_deps(name, {interface = true}))

                            elseif target:type() == "option" then
                                table.join2(results, target:get(name))
                            end
                            return results
                        end
    }

    -- get name flags for builder
    for _, flaginfo in ipairs(self:_nameflags()) do

        -- get flag info
        local flagscope     = flaginfo[1]
        local flagname      = flaginfo[2]
        local checkstate    = flaginfo[3]

        -- get getter
        local getter = getters[flagscope]
        if getter then

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
                if multival then
                    local results = mapper(self:_tool(), table.wrap(getter(flagname)), target, self:_targetkind())
                    for _, flag in ipairs(table.wrap(results)) do
                        if flag and flag ~= "" and (not checkstate or self:has_flags(flag)) then
                            table.insert(flags, flag)
                        end
                    end
                else
                    for _, flagvalue in ipairs(table.wrap(getter(flagname))) do
                        local flag = mapper(self:_tool(), flagvalue, target, self:_targetkind())
                        if flag and flag ~= "" and (not checkstate or self:has_flags(flag)) then
                            table.insert(flags, flag)
                        end
                    end
                end
            end
        end
    end
end

-- preprocess flags
function builder:_preprocess_flags(flags)

    -- remove repeat by right direction, because we need consider links/deps order
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
    if mapper then
        opt = opt or {}
        for _, value in ipairs(table.wrap(values)) do
            local flag = mapper(self:_tool(), value, opt.target, opt.targetkind)
            if flag and flag ~= "" and (not opt.check or self:has_flags(flag)) then
                table.join2(flags, flag)
            end
        end
    end
    if #flags > 0 then
        return flags
    end
end

-- return module
return builder
