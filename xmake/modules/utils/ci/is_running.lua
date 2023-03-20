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
-- @file        is_running.lua
--

-- is running on ci(travis/appveyor/...)?
function main()
    local on_ci = _g._ON_CI
    if on_ci == nil then
        local ci = (os.getenv("CI") or os.getenv("GITHUB_ACTIONS") or ""):lower()
        if ci == "true" or ci == "1" then
            on_ci = true
        else
            on_ci = false
        end
        _g._ON_CI = on_ci
    end
    return on_ci
end

