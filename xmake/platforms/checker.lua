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
-- @file        checker.lua
--

-- imports
import("core.base.option")
import("detect.sdk.find_xcode_dir")
import("detect.sdk.find_xcode_sdkvers")
import("lib.detect.find_tool")
import("lib.detect.find_toolname")

-- find the given tool
function _toolchain_check(config, toolkind, toolinfo)

    -- get the tool path
    local toolpath = config.get(toolkind)
    if not toolpath then

        -- get name
        local name = toolinfo.name

        -- get cross
        local cross = config.get("cross") or toolinfo.cross or ""

        -- get program name from the env if not cross-compilation
        if config.get("plat") == os.host() and config.get("arch") ==os.arch() then
            local program = os.getenv(toolkind:upper():split('-')[1])
            if program and program:trim() ~= "" then
                toolpath = find_tool(find_toolname(program), {program = program}) 
            end
        end

        -- attempt to check it 
        if not toolpath then
            toolpath = find_tool(name, {program = cross .. name, pathes = config.get("toolchains"), check = toolinfo.check})
        end

        -- check ok?
        if toolpath then 
            config.set(toolkind, toolpath) 
        end

        -- trace
        if option.get("verbose") then
            if toolpath then
                cprint("checking for %s (%s) ... ${green}%s", toolinfo.description, toolkind, path.filename(toolpath))
            else
                cprint("checking for %s (%s: ${red}%s${clear}) ... ${red}no", toolinfo.description, toolkind, name)
            end
        end
    end

    -- get tool path
    return toolpath
end

-- check all for the given config kind
function check(kind, checkers)

    -- import config module
    local config = import("core.project." .. kind)

    -- check all
    for _, checker in ipairs(checkers[kind]) do

        -- has arguments?
        local args = {}
        if type(checker) == "table" then
            for idx, arg in ipairs(checker) do
                if idx == 1 then
                    checker = arg
                else
                    table.insert(args, arg)
                end
            end
        end

        -- check it
        checker(config, unpack(args))
    end
end

-- check the architecture
function check_arch(config, default)

    -- get the architecture
    local arch = config.get("arch")
    if not arch then

        -- init the default architecture
        config.set("arch", default or os.arch())

        -- trace
        cprint("checking for the architecture ... ${green}%s", config.get("arch"))
    end
end

-- check the xcode application directory
function check_xcode_dir(config)

    -- get the xcode directory
    local xcode_dir = config.get("xcode_dir")
    if not xcode_dir then

        -- check ok? update it
        xcode_dir = find_xcode_dir()
        if xcode_dir then

            -- save it
            config.set("xcode_dir", xcode_dir)

            -- trace
            cprint("checking for the Xcode application directory ... ${green}%s", xcode_dir)
        else
            -- failed
            cprint("checking for the Xcode application directory ... ${red}no")
            cprint("${bright red}please run:")
            cprint("${red}    - xmake config --xcode_dir=xxx")
            cprint("${red}or  - xmake global --xcode_dir=xxx")
            raise()
        end
    end
end

-- check the xcode sdk version
function check_xcode_sdkver(config)

    -- get the xcode sdk version
    local xcode_sdkver  = config.get("xcode_sdkver")
    if not xcode_sdkver then

        -- check ok? update it
        xcode_sdkver = find_xcode_sdkvers({xcode_dir = config.get("xcode_dir"), plat = config.get("plat"), arch = config.get("arch")})[1]
        if xcode_sdkver then
            
            -- save it
            config.set("xcode_sdkver", xcode_sdkver)

            -- trace
            cprint("checking for the Xcode SDK version for %s ... ${green}%s", config.get("plat"), xcode_sdkver)
        else
            -- failed
            cprint("checking for the Xcode SDK version for %s ... ${red}no", config.get("plat"))
            cprint("${bright red}please run:")
            cprint("${red}    - xmake config --xcode_sdkver=xxx")
            cprint("${red}or  - xmake global --xcode_sdkver=xxx")
            raise()
        end
    end

    -- get target minver
    local target_minver = config.get("target_minver")
    if not target_minver then
        config.set("target_minver", xcode_sdkver)
    end
end

-- insert toolchain
function toolchain_insert(toolchains, toolkind, cross, name, description, check)

    -- insert to the given toolchain
    toolchains[toolkind] = toolchains[toolkind] or {}
    table.insert(toolchains[toolkind], {cross = cross, name = name, description = description, check = check})
end

-- check the toolchain 
function toolchain_check(config, toolkind, toolchains)

    -- load toolchains if be function
    if type(toolchains) == "function" then
        toolchains = toolchains(config)
    end

    -- check this toolchain
    for _, toolinfo in ipairs(toolchains[toolkind]) do
        if _toolchain_check(config, toolkind, toolinfo) then
            break
        end
    end

    -- save config
    config.save()
end

