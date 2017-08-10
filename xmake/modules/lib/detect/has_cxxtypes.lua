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
-- @file        has_cxxtypes.lua
--

-- imports
import("lib.detect.check_cxsnippets")

-- has the given c++ types?
--
-- @param types     the types
-- @param opt       the argument options
--                  .e.g 
--                  { verbose = false, target = [target|option], includes = .., config = {defines = .., ..}}
--
-- @return          true or false
--
-- @code
-- local ok = has_cxxtypes("wchar_t")
-- local ok = has_cxxtypes({"char*", "wchar_t"}, {includes = "stdio.h"})
-- @endcode
--
function main(types, opt)

    -- init options
    opt = opt or {}

    -- init types
    opt.sourcekind = "cxx"
    opt.types      = types
    
    -- has types?
    return check_cxsnippets("", opt)
end
