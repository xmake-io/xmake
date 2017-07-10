--!The Make-like Build Utility based on Lua
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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
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

    -- get it
    return self._TOOL
end

-- get the name flags
function builder:_nameflags()

    -- get it
    return self._NAMEFLAGS
end

-- get the target kind
function builder:_targetkind()

    -- get it
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

    -- get it
    return self._FLAGKINDS
end

-- add flags from the configure 
function builder:_addflags_from_config(flags)

    -- done
    for _, flagkind in ipairs(self:_flagkinds()) do
        table.join2(flags, config.get(flagkind))
    end
end

-- add flags from the target 
function builder:_addflags_from_target(flags, target)

    -- add the target flags 
    for _, flagkind in ipairs(self:_flagkinds()) do
        table.join2(flags, self:_mapflags(target:get(flagkind)))
    end

    -- for target options? 
    if target.options then

        -- add the flags for the target options
        for _, opt in ipairs(target:options()) do

            -- add the flags from the option
            self:_addflags_from_target(flags, opt)
        end
    end
end

-- add flags from target deps
function builder:_addflags_from_targetdeps(results, target, flagname)

    -- for all target deps
    for _, dep in ipairs(target:deps()) do

        -- is static or shared target library? link it
        local depkind = dep:get("kind")
        local targetkind = target:get("kind")
        if depkind == "static" or depkind == "shared" then
            if flagname == "links" and (targetkind == "binary" or targetkind == "shared") then

                -- add dependent link
                table.insert(results, dep:name())

            elseif flagname == "linkdirs" and (targetkind == "binary" or targetkind == "shared") then

                -- add dependent linkdirs
                table.insert(results, path.directory(dep:targetfile()))

            elseif flagname == "rpathdirs" and targetkind == "binary" then

                -- add dependent rpathdirs (need absolute path)
                table.insert(results, path.directory(path.absolute(dep:targetfile(), xmake._PROJECT_DIR)))

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

-- add flags from the argument option 
function builder:_addflags_from_argument(flags, args)
    for _, flagkind in ipairs(self:_flagkinds()) do
        table.join2(flags, self:_mapflags(args[flagkind]))
    end
end

-- add flags (named) from the language 
function builder:_addflags_from_language(flags, target)

    -- init getters
    local getters =
    {
        config      =   config.get
    ,   platform    =   platform.get
    ,   target      =   function (name) 

                            -- get flagvalues of target with given flagname
                            local results = table.wrap(target:get(name))

                            -- link? add includes and links of all dependent targets
                            if name == "links" or name == "linkdirs" or name == "rpathdirs" or name == "includedirs" then
                                self:_addflags_from_targetdeps(results, target, name)
                            end

                            -- ok?
                            return results
                        end
    ,   option      =   function (name)

                            -- only for target (exclude option)
                            if target.options then
                                local results = {}
                                for _, opt in ipairs(target:options()) do
                                    table.join2(results, table.wrap(opt:get(name)))
                                end
                                return results
                            end
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
        assert(getter)

        -- get api name of tool 
        --
        -- .e.g
        --
        -- defines => define
        -- defines_if_ok => define
        -- ...
        --
        local apiname = flagname:split('_')[1]
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

-- get feature of the tool
function builder:feature(name)

    -- get it
    local features = self:get("features")
    if features then
        return features[name]
    end
end

-- return module
return builder
