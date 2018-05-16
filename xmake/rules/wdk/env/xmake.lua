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
-- @file        xmake.lua
--

-- define rule: environment
rule("wdk.env")

    -- on load
    on_load(function (target)

        -- imports
        import("detect.sdks.find_wdk")

        -- load wdk environment
        if not target:data("wdk") then

            -- find wdk
            local wdk = assert(find_wdk(nil, {verbose = true}), "WDK not found!")

            -- update the umdf sdk version from the xmake.lua
            local umdfver = target:values("wdk.umdf.sdkver")
            if umdfver then
                wdk.umdfver = umdfver
            end

            -- update the kmdf sdk version from the xmake.lua
            local kmdfver = target:values("wdk.kmdf.sdkver")
            if kmdfver then
                wdk.kmdfver = kmdfver
            end

            -- save wdk
            target:data_set("wdk", wdk)
        end
    end)

    -- clean files
    after_clean(function (target)
        for _, file in ipairs(target:data("wdk.cleanfiles")) do
            os.rm(file)
        end
        target:data_set("wdk.cleanfiles", nil)
    end)

