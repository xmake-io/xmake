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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define theme
theme("plain")

    -- the success status
    set_text("success", "$ok")
    set_color("success", "")

    -- the failure status
    set_text("failure", "$failed")
    set_color("failure", "")

    -- the nothing status
    set_text("nothing", "$no")
    set_color("nothing", "")

    -- the error info
    set_text("error", "$error")
    set_color("error", "")

    -- the warning info
    set_text("warning", "$warning")
    set_color("warning", "")

    -- the building progress
    set_text("build.progress_format", "[%3d%%]")
    set_text("build.progress_style", "scroll")
    set_color("build.progress", "")

    -- the building object file
    set_color("build.object", "")

    -- the building target file
    set_color("build.target", "")

    -- the spinner chars
    set_text("spinner.chars", '\\', '-', '/', '|')

    -- color dump
    set_text("dump.default_format", "%s")
    set_text("dump.udata_format", "%s")
    set_text("dump.table_format", "%s")
    set_text("dump.anchor", "&%s")
    set_text("dump.reference", "*%s")
    set_color("dump.anchor", "")
    set_color("dump.reference", "")
    set_color("dump.default", "")
    set_color("dump.udata", "")
    set_color("dump.table", "")
    set_color("dump.string", "")
    set_color("dump.string_quote", "")
    set_color("dump.keyword", "")
    set_color("dump.number", "")
    set_color("dump.function", "")

    -- menu
    set_color("menu.main.task.name", "")
    set_color("menu.option.name", "")
    set_color("menu.usage", "")

    -- interactive mode
    set_text("interactive.prompt", "xmake>")
    set_text("interactive.prompt2", "xmake>>")
    set_color("interactive.prompt", "")
    set_color("interactive.prompt2", "")
