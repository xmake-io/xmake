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
theme("dark")

    -- the success status 
    set_text("success", "ok")
    set_color("success", "green")

    -- the failure status 
    set_text("failure", "failed")
    set_color("failure", "red")

    -- the nothing status 
    set_text("nothing", "no")
    set_color("nothing", "red")

    -- the error info
    set_text("error", "error")
    set_color("error", "red")

    -- the warning info
    set_text("warning", "warn")
    set_color("warning", "cyan")

    -- the building progress
    set_text("build.progress_format", "[%3d%%]")
    set_color("build.progress", "green")

    -- the building object file
    set_color("build.object", "")

    -- the building target file
    set_color("build.target", "magenta")

