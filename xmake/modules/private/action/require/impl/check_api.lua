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
-- @file        check_api.lua
--

import("private.check.checker")
import("private.check.show")

function main(package, opt)
    opt = opt or {}

    local checkers = checker.checkers()
    for name, info in table.orderpairs(checkers) do
        if (info.load and opt.load) or (info.download_failure and opt.download_failure) then
            local check = import("private.check.checkers." .. name, {anonymous = true})
            check({package = package, show = show.wshow})
        end
    end
end
