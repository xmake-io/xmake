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
    set_color("error", "red bright")

    -- the warning info
    set_text("warning", "warning $warning")
    set_color("warning", "yellow bright")

    -- the building progress
    set_text("build.progress_format", "[%3d%%]")
    set_text("build.progress_style", "scroll")
    set_color("build.progress", "green bright")

    -- the building object file
    set_color("build.object", "")

    -- the building target file
    set_color("build.target", "magenta bright")

    -- the spinner chars
    set_text("spinner.chars", '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')

    -- color dump
    set_text("dump.default_format", "%s")
    set_text("dump.udata_format", "%s")
    set_text("dump.table_format", "%s")
    set_text("dump.anchor", "${anchor}  %s")
    set_text("dump.reference", "${sailboat}  %s")
    set_color("dump.anchor", "yellow")
    set_color("dump.reference", "yellow")
    set_color("dump.default", "red")
    set_color("dump.udata", "yellow")
    set_color("dump.table", "bright")
    set_color("dump.string", "magenta bright")
    set_color("dump.string_quote", "magenta")
    set_color("dump.keyword", "blue")
    set_color("dump.number", "green")
    set_color("dump.function", "cyan")

    -- menu
    set_color("menu.main.task.name", "magenta")
    set_color("menu.option.name", "green")
    set_color("menu.usage", "cyan")

    -- interactive mode
    set_text("interactive.prompt", "xmake>")
    set_text("interactive.prompt2", "xmake>>")
    set_color("interactive.prompt", "green")
    set_color("interactive.prompt2", "green")
