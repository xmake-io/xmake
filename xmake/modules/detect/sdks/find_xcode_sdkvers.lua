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
-- @file        find_xcode_sdkvers.lua
--

-- imports
import("core.project.config")
import("detect.sdks.find_xcode_dir")

-- find xcode sdk versions for the given platform 
--
-- @param opt   the argument options 
--              .e.g {xcode_dir = "", plat = "[iphoneos|watchos]", arch = "[armv7|armv7s|arm64|i386|x86_64]"}
--
-- @return      the xcode sdk version array
--
-- @code 
--
-- local xcode_sdkvers = find_xcode_sdkvers()
-- local xcode_sdkvers = find_xcode_sdkvers({xcode_dir = ""})
-- local xcode_sdkvers = find_xcode_sdkvers({xcode_dir = "", plat = "iphoneos", arch = "arm64"})
-- 
-- @endcode
--
function main(opt)

    -- init arguments
    opt = opt or {}

    -- get xcode directory
    local xcode_sdkvers = {}
    local xcode_dir = opt.xcode_dir or find_xcode_dir() 
    if not os.isdir(xcode_dir) then
        return xcode_sdkvers
    end

    -- get plat and arch
    local plat = opt.plat or config.get("plat") or "macosx"
    local arch = opt.arch or config.get("arch") or "x86_64"

    -- select xcode sdkdir
    local xcode_sdkdir = nil
    if plat == "macosx" then
        xcode_sdkdir = "Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX*.sdk"
    elseif plat == "iphoneos" then
        if arch == "i386" or arch == "x86_64" then
            xcode_sdkdir = "Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator*.sdk"
        else
            xcode_sdkdir = "Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk"
        end
    elseif plat == "watchos" then
        if arch == "i386" or arch == "x86_64" then
            xcode_sdkdir = "Contents/Developer/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator*.sdk"
        else
            xcode_sdkdir = "Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/WatchOS*.sdk"
        end
    end

    -- attempt to match the directory
    if xcode_sdkdir then
        for _, dir in ipairs(os.dirs(path.join(xcode_dir, xcode_sdkdir))) do
            local xcode_sdkver = dir:match("%d+%.%d+")
            if xcode_sdkver then 
                table.insert(xcode_sdkvers, xcode_sdkver)
            end
        end
    end

    -- ok?    
    return xcode_sdkvers
end
