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

-- add *.manifest for windows
-- https://github.com/xmake-io/xmake/issues/1241
rule("platform.windows.manifest")
    set_extensions(".manifest")
    on_config("windows", function (target)
        if not target:is_binary() then
            return
        end
        if target:has_tool("ld", "link") then
            local manifest = false
            local sourcebatch = target:sourcebatches()["platform.windows.manifest"]
            if sourcebatch then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    target:add("ldflags", "/ManifestInput:" .. path.translate(sourcefile), {force = true})
                    manifest = true
                    break
                end
            end
            if manifest then
                target:add("ldflags", "/manifest:embed", {force = true})
            end
        end
    end)
