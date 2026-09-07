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
-- @author      Willaaaaaaa
-- @file        configs.lua
--

import("core.base.hashset")
import("private.check.checker")

function main(opt)
    opt = opt or {}
    local package = opt.package
    if not package then
        return
    end

    local valid_configs = hashset.from(table.wrap(package:get("configs")))
    local requireinfo = package:requireinfo()
    local required_configs = requireinfo and requireinfo.configs or {}
    for name, _ in pairs(required_configs) do
        if not valid_configs:has(name) then
            opt.show(string.format(
                "package(%s %s): invalid config(%s) is ignored, please run `xmake require --info %s` to get all valid configurations!",
                package:displayname(), package:version_str(), name, package:name()))
            checker.update_stats("warning")
        end
    end
end
