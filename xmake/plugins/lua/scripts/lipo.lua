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
-- @file        lipo.lua
--

-- imports
import("detect.tool.find_lipo")

-- main
--
-- .e.g.
--
-- xmake l lipo "-create -arch armv7 file -arch arm64 file -output file"
function main(...)

    -- get arguments
    local args = {...}
    if not args or #args ~= 1 then
        raise("invalid arguments!")
    end
    args = args[1]

    -- find the lipo
    local lipo = find_lipo()
    assert(lipo, "lipo not found!")

    -- run it
    os.run("%s %s", lipo, args)
end

