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
        if not target:is_binary() and not target:is_shared() then
            return
        end
        if target:has_tool("ld", "link") or target:has_tool("sh", "link") then
            local manifest = false
            local uac = false
            local sourcebatch = target:sourcebatches()["platform.windows.manifest"]
            if sourcebatch then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    target:add("ldflags", "/manifestinput:" .. path.translate(sourcefile), {force = true})
                    target:add("shflags", "/manifestinput:" .. path.translate(sourcefile), {force = true})
                    target:data_add("linkdepfiles", sourcefile)
                    manifest = true
                    local content = io.readfile(sourcefile)
                    if content then
                        content = content:gsub("<!%-%-.-%-%->", "")
                        if content:find("requestedPrivileges", 1, true) then
                            uac = true
                        end
                    end
                    break
                end
            end
            if manifest then
                -- if manifest file is provided, we need disable default UAC manifest
                -- @see https://github.com/xmake-io/xmake/pull/4362
                if uac then
                    target:add("ldflags", "/manifestuac:no", {force = true})
                end
                target:add("shflags", "/manifestuac:no", {force = true})

                target:add("ldflags", "/manifest:embed", {force = true})
                target:add("shflags", "/manifest:embed", {force = true})
            else
                local level = target:policy("windows.manifest.uac")
                if level then
                    local level_maps = {
                        invoker = "asInvoker",
                        admin = "requireAdministrator",
                        highest = "highestAvailable"
                    }
                    assert(level_maps[level], "unknown uac level %s, please set invoker, admin or highest", level)
                    local ui = target:policy("windows.manifest.uac.ui") or false
                    target:add("ldflags", "/manifest:embed", {("/manifestuac:level='%s' uiAccess='%s'"):format(level_maps[level], ui)}, {force = true, expand = false})
                end
            end
        end
    end)
