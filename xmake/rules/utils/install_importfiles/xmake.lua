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

-- install pkg-config/*.pc import files
rule("utils.install.pkgconfig_importfiles")
    after_install(function (target, opt)
        opt = opt or {}
        local configs = target:extraconf("rules", "utils.install.pkgconfig_importfiles")
        import("target.action.install.pkgconfig_importfiles")(target, table.join(opt, configs))
    end)

-- install *.cmake import files
rule("utils.install.cmake_importfiles")
    after_install(function (target, opt)
        opt = opt or {}
        local configs = target:extraconf("rules", "utils.install.cmake_importfiles")
        import("target.action.install.cmake_importfiles")(target, table.join(opt, configs))
    end)
