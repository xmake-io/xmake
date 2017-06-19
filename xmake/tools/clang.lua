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
-- @file        clang.lua
--

-- inherit gcc
inherit("gcc")

-- init it
function init(shellname, kind)
    
    -- init super
    _super.init(shellname or "clang", kind)

    -- init shflags
    _super._g.shflags = { "-dynamiclib", "-fPIC" }

    -- link stdc++ for clang
    _super._g.ldflags = {}
    if _super._g.shellname:find("clang", 1, true) then
        table.insert(_super._g.ldflags, "-lstdc++")
        table.insert(_super._g.shflags, "-lstdc++")
    end

    -- suppress warning 
    _super._g.cxflags = {"-Qunused-arguments"}
    _super._g.mxflags = {"-Qunused-arguments"}
    _super._g.asflags = {"-Qunused-arguments"}

    -- init flags map
    _super._g.mapflags["-s"] = "-Wl,-S"
    _super._g.mapflags["-S"] = "-Wl,-S"
end

-- make the strip flag
function nf_strip(level)

    -- the maps
    local maps = 
    {   
        debug       = "-Wl,-S"
    ,   all         = "-Wl,-S"
    }

    -- make it
    return maps[level] or ""
end
