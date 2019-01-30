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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")
import("privilege.sudo")

-- install package
--
-- @param name  the package name
-- @param opt   the options, .e.g {verbose = true, apt = "the package name"}
--
-- @return      true or false
--
function main(name, opt)

    -- init options
    opt = opt or {}

    -- find apt
    local apt = find_tool("apt")
    if not apt then
        raise("apt not found!")
    end

    -- init argv
    local argv = {"install", "-y", opt.apt or name}

    -- install package directly if the current user is root
    if os.isroot() then
        os.vrunv(apt.program, argv)
    -- install with administrator permission?
    elseif sudo.has() then

        -- get confirm
        local confirm = option.get("yes")
        if confirm == nil then

            -- show tips
            cprint("${bright color.warning}note: ${clear}try installing %s with administrator permission?", name)
            cprint("please input: y (y/n)")

            -- get answer
            io.flush()
            local answer = io.read()
            if answer == 'y' or answer == '' then
                confirm = true
            end
        end

        -- install it if be confirmed
        if confirm then
            sudo.vrunv(apt.program, argv)
        end
    else
        raise("cannot get administrator permission!")
    end
end
