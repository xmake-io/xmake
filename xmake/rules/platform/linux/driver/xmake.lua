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

-- build linux driver module
rule("platform.linux.driver")
    set_sourcekinds("cc")
    on_load(function (target)
        import("driver_modules").load(target)
    end)
    on_config(function (target)
        import("driver_modules").config(target)
    end)
    on_link(function (target, opt)
        import("driver_modules").link(target, opt)
    end)

