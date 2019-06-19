--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
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
theme("emoji")

    -- the success status 
    set_text("success", "heavy_check_mark")
    set_color("success", "")

    -- the failure status 
    set_text("failure", "x")
    set_color("failure", "")

    -- the nothing status 
    set_text("nothing", "o")
    set_color("nothing", "")

    -- the error info
    set_text("error", "exclamation error")
    set_color("error", "red")

    -- the warning info
    set_text("warning", "warning $warning")
    set_color("warning", "yellow")

    -- the building progress
    set_text("build.progress_format", "[%3d%%]")
    set_color("build.progress", "green")

    -- the building object file
    set_color("build.object", "")

    -- the building target file
    set_color("build.target", "magenta")

    -- color dump
    set_color("dump.string", "magenta")
    set_color("dump.keyword", "blue")
    set_color("dump.number", "green")
    set_color("dump.function", "cyan")

