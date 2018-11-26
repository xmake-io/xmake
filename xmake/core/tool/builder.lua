--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
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

-- map gcc flag to the given builder flag
function builder:_mapflag(flag, mapflags)

    -- attempt to map it directly
    local flag_mapped = mapflags[flag]
    if flag_mapped then
        return flag_mapped
    end

    -- find and replace it using pattern
    for k, v in pairs(mapflags) do
        local flag_mapped, count = flag:gsub("^" .. k .. "$", function (w) return v end)
        if flag_mapped and count ~= 0 then
            return utils.ifelse(#flag_mapped ~= 0, flag_mapped, nil) 
        end
    end

    -- has this flag?
    if self:has_flags(flag) then
        return flag
    end
end

-- map gcc flags to the given builder flags
function builder:_mapflags(flags)

    -- wrap flags first
    flags = table.wrap(flags)

    -- done
    local results = {}
    local mapflags = self:get("mapflags")
    if mapflags then

        -- map flags
        for _, flag in pairs(flags) do
            local flag_mapped = self:_mapflag(flag, mapflags)
            if flag_mapped then
                table.insert(results, flag_mapped)
            end
        end

    else

        -- has flags?
        for _, flag in pairs(flags) do
            if self:has_flags(flag) then
                table.insert(results, flag)
            end
        end

    end

    -- ok?
    return results
end

-- get the flag kinds
function builder:_flagkinds()
    return self._FLAGKINDS
end

-- inherts from target packages
function builder:_inherit_from_targetpkgs(values, target, name)
    for _, pkg in ipairs(target:packages()) do
        -- uses them instead of the builtin configs if exists extra package config
        -- e.g. `add_packages("xxx", {links = "xxx"})`
        local configinfo = target:pkgconfig(pkg:name())
        if configinfo and configinfo[name] then
            table.join2(values, configinfo[name])
        else
            -- uses the builtin package configs
            table.join2(values, pkg:get(name))
        end
    end
end

-- inherts from target deps
function builder:_inherit_from_target(values, target, name)
    table.join2(values, target:get(name))
    if target:type() == "target" then
        for _, opt in ipairs(target:options()) do
            table.join2(values, opt:get(name))
        end
        self:_inherit_from_targetpkgs(values, target, name)
    end
end

-- inherts from target deps
function builder:_inherit_from_targetdeps(results, target, flagname)

    -- for all target deps
    local orderdeps = target:orderdeps()
    local total = #orderdeps
    for idx, _ in ipairs(orderdeps) do

        -- reverse deps order for links
        local dep = orderdeps[total + 1 - idx]

        -- is static or shared target library? link it
        local depkind      = dep:get("kind")
        local targetkind   = target:get("kind")
        local depconfig    = table.wrap(target:depconfig(dep:name()))
        if (depkind == "static" or depkind == "shared" or depkind == "object") and (depconfig.inherit == nil or depconfig.inherit) then
            if (flagname == "links" or flagname == "syslinks") and (targetkind == "binary" or targetkind == "shared") then

                -- add dependent link
                if depkind ~= "object" then
                    table.insert(results, dep:basename())
                end

                -- inherit links from the depdent target
                self:_inherit_from_target(results, dep, flagname)

            elseif flagname == "linkdirs" and (targetkind == "binary" or targetkind == "shared") then

                -- add dependent linkdirs
                if depkind ~= "object" then
                    table.insert(results, path.directory(dep:targetfile()))
                end

                -- inherit linkdirs from the depdent target
                self:_inherit_from_target(results, dep, flagname)

            elseif flagname == "rpathdirs" and (targetkind == "binary" or targetkind == "shared") then

                -- add dependent rpathdirs 
                if depkind ~= "object" then
                    local rpathdir = "@loader_path"
                    local subdir = path.relative(path.directory(dep:targetfile()), path.directory(target:targetfile()))
                    if subdir and subdir ~= '.' then
                        rpathdir = path.join(rpathdir, subdir)
                    end
                    table.insert(results, rpathdir)
                end

            elseif flagname == "includedirs" then

                -- add dependent headerdir
                if dep:get("headers") and os.isdir(dep:headerdir()) then
                    table.insert(results, dep:headerdir())
                end
                
                -- add dependent configheader directory
                local configheader = dep:configheader()
                if configheader and os.isfile(configheader) then
                    table.insert(results, path.directory(configheader))
                end
            end
        end
    end
end

-- add flags from the configure 
function builder:_addflags_from_config(flags)
    for _, flagkind in ipairs(self:_flagkinds()) do
        table.join2(flags, config.get(flagkind))
    end
end

-- add flags from the option 
function builder:_addflags_from_option(flags, opt)
    for _, flagkind in ipairs(self:_flagkinds()) do
        table.join2(flags, self:_mapflags(opt:get(flagkind)))
    end
end

-- add flags from the package 
function builder:_addflags_from_package(flags, pkg)
    for _, flagkind in ipairs(self:_flagkinds()) do
        table.join2(flags, self:_mapflags(pkg:get(flagkind)))
    end
end

-- add flags from the target 
function builder:_addflags_from_target(flags, target)

    -- no target?
    if not target then
        return
    end
 
    -- init cache
    self._TARGETFLAGS = self._TARGETFLAGS or {}
    local cache = self._TARGETFLAGS

    -- get flags from cache first
    local key = tostring(target)
    local targetflags = cache[key]
    if not targetflags then
    
        -- add flags (named) and inherited flags from language
        targetflags = {}
        self:_addflags_from_language(targetflags, target)

        -- add flags for the target 
        if target:type() == "target" then

            -- add flags from options
            for _, opt in ipairs(target:options()) do
                self:_addflags_from_option(targetflags, opt)
            end

            -- add flags from packages
            for _, pkg in ipairs(target:packages()) do
                self:_addflags_from_package(targetflags, pkg)
            end
        end

        -- add the target flags 
        for _, flagkind in ipairs(self:_flagkinds()) do
            
            -- get flags and extra info
            local flags = target:get(flagkind)
            local flagextra = target:get("__extra_" .. flagkind)
            if flagextra then
                for _, flag in ipairs(table.wrap(flags)) do
                    if (flagextra[flag] or {}).force then
                        table.join2(targetflags, flag)
                    else
                        table.join2(targetflags, self:_mapflags(flag))
                    end
                end
            else
                table.join2(targetflags, self:_mapflags(flags))
            end
        end

        -- cache it
        cache[key] = targetflags
    end

    -- add flags
    table.join2(flags, targetflags)
end

-- add flags from the argument option 
function builder:_addflags_from_argument(flags, target, args)

    -- add flags from the flag kinds (cxflags, ..)
    for _, flagkind in ipairs(self:_flagkinds()) do

        -- add auto mapping flags
        table.join2(flags, self:_mapflags(args[flagkind]))

        -- add original flags
        local original_flags = (args.force or {})[flagkind]
        if original_flags then
            table.join2(flags, original_flags)
        end
    end

    -- add flags (named) from the language 
    if target then
        local key = target:type()
        self:_addflags_from_language(flags, target, {[key] = function (name) return args[name] end})
    end
end

-- add flags (named) from the language 
function builder:_addflags_from_language(flags, target, getters)

    -- init getters
    local getters = getters or
    {
        config      =   config.get
    ,   platform    =   platform.get
    ,   target      =   function (name) 

                            -- only for target
                            local results = {}
                            if target:type() == "target" then

                                -- link? add includes and links of all dependent targets first
                                if name == "links" or name == "syslinks" or name == "linkdirs" or name == "rpathdirs" or name == "includedirs" then
                                    self:_inherit_from_targetdeps(results, target, name)
                                end

                                -- get flagvalues of target with given flagname
                                table.join2(results, target:get(name))
                            end

                            -- ok?
                            return results
                        end
    ,   option      =   function (name)

                            -- is target? get flagvalues of the attached options and packages
                            local results = {}
                            if target:type() == "target" then
                                for _, opt in ipairs(target:options()) do
                                    table.join2(results, table.wrap(opt:get(name)))
                                end
                                self:_inherit_from_targetpkgs(results, target, name)

                            -- is option? get flagvalues of option with given flagname
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
            --
            -- ignore "nf_" and "_if_ok"
            --
            -- .e.g
            --
            -- defines => define
            -- defines_if_ok => define
            -- ...
            --
            local apiname = flagname:gsub("^nf_", ""):gsub("_if_ok$", "")
            if apiname:endswith("s") then
                apiname = apiname:sub(1, #apiname - 1)
            end

            -- map name flag to real flag
            local mapper = self:_tool()["nf_" .. apiname]
            if mapper then
                
                -- add the flags 
                for _, flagvalue in ipairs(table.wrap(getter(flagname))) do

                    -- map and check flag
                    local flag = mapper(self:_tool(), flagvalue, target, self:_targetkind())
                    if flag and flag ~= "" and (not checkstate or self:has_flags(flag)) then
                        table.join2(flags, flag)
                    end
                end
            end
        end
    end
end

-- preprocess flags
function builder:_preprocess_flags(flags)

    -- remove repeat
    flags = table.unique(flags)

    -- split flag group, .e.g "-I /xxx" => {"-I", "/xxx"}
    local results = {}
    for _, flag in ipairs(flags) do
        flag = flag:trim()
        if #flag > 0 then
            if flag:find(" ", 1, true) then
                table.join2(results, os.argv(flag))
            else
                table.insert(results, flag)
            end
        end
    end

    -- get it
    return results 
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

-- get properties of the tool
function builder:get(name)
    return self:_tool():get(name)
end

-- has flags?
function builder:has_flags(flags)
    return self:_tool():has_flags(flags)
end

-- get the format of the given target kind 
function builder:format(targetkind)

    -- get formats
    local formats = self:get("formats")
    if formats then
        return formats[targetkind]
    end
end

-- get buildmode of the tool
function builder:buildmode(name)

    -- get it
    local buildmodes = self:get("buildmodes")
    if buildmodes then
        return buildmodes[name]
    end
end

-- return module
return builder
