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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      Shiffted
-- @file        requires.lua
--

-- imports
import(".api_checker")

-- check api configurations in `add_requires`
function main(opt)
    opt = opt or {}

    api_checker.check_requires("package", table.join(opt, {check = function(require_instance , value)
        if not require_instance.package then
            return false, string.format("unknown package '%s', not found in any repository", value)
        end
        return true
    end}))

    api_checker.check_requires("configs", table.join(opt, {values = function(require_instance)
        local package = require_instance.package

        -- skip unresolved and 3rd-party packages (e.g. vcpkg::, conan::)
        if not package or package:name():find("::", 1, true) then
            return nil
        end
        return package:get("configs") or {}
    end}))
end
