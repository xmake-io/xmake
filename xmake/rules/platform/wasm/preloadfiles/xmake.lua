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

-- @see https://github.com/xmake-io/xmake/issues/3613
rule("platform.wasm.preloadfiles")
    on_load("wasm", function (target)
        if not target:is_binary() then
            return
        end
        local preloadfiles = target:values("wasm.preloadfiles")
        if preloadfiles then
            for _, preloadfile in ipairs(preloadfiles) do
                target:add("ldflags", {"--preload-file", preloadfile}, {force = true, expand = false})
            end
        end
    end)

