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
-- @file        find_ndk_sdkvers.lua
--

-- find ndk sdk versions 
--
-- @param ndk_dir   the ndk directory
--
-- @return          the ndk sdk version array
--
-- @code 
--
-- local ndk_sdkvers = find_ndk_sdkvers("/xxx/android-ndk-r10e")
-- 
-- @endcode
--
function main(ndk_dir)

    -- get ndk directory
    if not ndk_dir or not os.isdir(ndk_dir) then
        return {}
    end

    -- find all sdk directories
    local ndk_sdkvers = {}
    for _, sdkdir in ipairs(os.dirs(path.join(ndk_dir, "platforms/android-*"))) do

        -- get version
        local filename = path.filename(sdkdir)
        local version, count = filename:gsub("android%-", "")
        if count > 0 then

            -- get the max version
            if tonumber(version) > 0 then
                table.insert(ndk_sdkvers, version) 
            end
        end
    end

    -- ok?    
    return ndk_sdkvers
end
