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
-- @file        find_ndk_toolchains.lua
--

-- imports
import("core.project.config")

-- find ndk toolchains
--
-- @param ndk_dir   the ndk directory
-- @param opt       the argument options 
--                  .e.g {arch = "[armv5te|armv6|armv7-a|armv8-a|arm64-v8a]"}
--
-- @return          the toolchains array. .e.g {{bin = .., cross = ..}, .. }
--
-- @code 
--
-- local ndk_toolchains = find_ndk_toolchains("/xxx/android-ndk-r10e")
-- local ndk_toolchains = find_ndk_toolchains("/xxx/android-ndk-r10e", {arch = "arm64-v8a"})
-- 
-- @endcode
--
function main(ndk_dir, opt)

    -- init arguments
    opt = opt or {}

    -- get ndk directory
    if not ndk_dir or not os.isdir(ndk_dir) then
        return {}
    end

    -- get arch
    local arch = opt.arch or config.get("arch") or "armv7-a"

    -- is arm64?
    local arm64 = arch and arch:startswith("arm64")

    -- the cross
    local cross = ifelse(arm64, "aarch64-linux-android-", "arm-linux-androideabi-")

    -- save the toolchains directory
    local ndk_toolchains = {}
    for _, bindir in ipairs(os.dirs(path.join(ndk_dir, "toolchains", cross .. "**", "prebuilt/*/bin"))) do
        local binfiles = os.files(path.join(bindir, cross .. "*"))
        if binfiles and #binfiles > 0 then
            table.insert(ndk_toolchains, {bin = bindir, cross = cross})
        end
    end

    -- ok?    
    return ndk_toolchains
end
