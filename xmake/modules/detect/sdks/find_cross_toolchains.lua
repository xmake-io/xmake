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
-- @file        find_cross_toolchains.lua
--

-- imports
import("core.project.config")

-- find cross toolchains
--
-- @param rootdir   the root directory of cross toolchains 
-- @param opt       the argument options 
--                  .e.g {bin = .., cross = ..}
--
-- @return          the toolchains array. .e.g {{bin = .., cross = ..}, .. }
--
-- @code 
--
-- local cross_toolchains = find_cross_toolchains("/xxx/android-cross-r10e")
-- local cross_toolchains = find_cross_toolchains("/xxx/android-cross-r10e", {cross = "arm-linux-androideabi-"})
-- local cross_toolchains = find_cross_toolchains("/xxx/android-cross-r10e", {cross = "arm-linux-androideabi-", bin = ..})
-- 
-- @endcode
--
function main(rootdir, opt)

    -- init arguments
    opt = opt or {}

    -- get root directory
    if not rootdir or not os.isdir(rootdir) then
        return {}
    end

    -- find bin directory and cross
    local cross_toolchains = {}
    for _, ldpath in ipairs(os.files(path.join(opt.bin or rootdir, "**" .. (opt.cross or '-') .. "ld"))) do
        table.insert(cross_toolchains, {bin = path.directory(ldpath), cross = path.basename(ldpath):sub(1, -3)})
    end

    -- ok?    
    return cross_toolchains
end
