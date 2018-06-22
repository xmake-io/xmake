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
-- @file        find_cross_toolchain.lua
--

-- imports
import("core.project.config")
import("lib.detect.find_file")

-- find cross toolchain
--
-- @param rootdir   the root directory of cross toolchain 
-- @param opt       the argument options 
--                  .e.g {bin = .., cross = ..}
--
-- @return          the toolchain .e.g {bin = .., cross = ..}
--
-- @code 
--
-- local toolchain = find_cross_toolchain("/xxx/android-cross-r10e")
-- local toolchain = find_cross_toolchain("/xxx/android-cross-r10e", {cross = "arm-linux-androideabi-"})
-- local toolchain = find_cross_toolchain("/xxx/android-cross-r10e", {cross = "arm-linux-androideabi-", bin = ..})
-- 
-- @endcode
--
function main(rootdir, opt)

    -- init arguments
    opt = opt or {}

    -- get root directory
    if not rootdir or not os.isdir(rootdir) then
        return 
    end

    -- init pathes
    local pathes = {}
    if opt.bin then
        table.insert(pathes, opt.bin)
    end
    table.insert(pathes, path.join(rootdir, "bin"))
    table.insert(pathes, path.join(rootdir, "**", "bin"))

    -- attempt to find *-ld
    local ldname = os.host() == "windows" and "ld.exe" or "ld"
    local ldpath = find_file((opt.cross or '*-') .. ldname, pathes)
    if ldpath then
        return {bin = path.directory(ldpath), cross = path.basename(ldpath):sub(1, -3)}
    end
    
    -- find ld
    ldpath = find_file(ldname, pathes)
    if ldpath then
        return {bin = path.directory(ldpath), cross = ""}
    end
end
