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
-- @file        find_qt.lua
--

-- imports
import("lib.detect.find_file")

-- find qt sdk directory
function _find_sdkdir()

    -- init the search directories
    local pathes = {}
    if os.host() == "macosx" then
        table.insert(pathes, "~/Qt")
    elseif os.host() == "windows" then
    else
        table.insert(pathes, "~/Qt")
    end

end

-- find qt sdk toolchains
--
-- @param sdkdir    the qt sdk directory
-- @param opt       the argument options 
--
-- @return          the qt sdk toolchains. .e.g {sdkdir = ..., bindir = .., linkdirs = ..., includedirs = ..., .. }
--
-- @code 
--
-- local toolchains = find_qt("/Developer/NVIDIA/qt-9.1")
-- 
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- find qt directory
    if not sdkdir or not os.isdir(sdkdir) then
        sdkdir = _find_sdkdir()
    end

    -- not found?
    if not sdkdir or not os.isdir(sdkdir) then
        return nil
    end

    -- get toolchains
    return {}
end
