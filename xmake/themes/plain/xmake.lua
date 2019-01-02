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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define theme
theme("plain")

    -- set color of the error info
    set_color("error", "")
    set_color("error.verbose", "")

    -- set color of the warning info
    set_color("warning", "")
    set_color("warning.verbose", "")

    -- the color of the building progress
    set_color("build.progress", "")

    -- the color of the building object file
    set_color("build.object", "")
    set_color("build.object.verbose", "")

    -- the color of the building target file
    set_color("build.target", "")
    set_color("build.target.verbose", "")
