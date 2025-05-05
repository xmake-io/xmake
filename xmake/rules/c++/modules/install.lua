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
-- @author      ruki, Arthapz
-- @file        install.lua
--

import("support")
import("scanner")
import("builder")

function install(target)
    -- we cannot use target:data("cxx.has_modules"),
    -- because on_config will be not called when installing targets
    if support.contains_modules(target) then
        local modules = scanner.get_modules(target)
        builder.generate_metadata(target, modules)
        support.add_installfiles_for_modules(target, modules)
    end
end

function uninstall(target)
    if support.contains_modules(target) then
        local modules = scanner.get_modules(target)
        support.add_installfiles_for_modules(target, modules)
    end
end
