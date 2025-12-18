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
-- @author      ruki
-- @file        basic.lua
--

function main(target)
    local mode = (type(target:values("swift.interop")) == "string") and target:values("swift.interop") or "objc"
    if mode == "cxx" then
        target:add("scflags", "-cxx-interoperability-mode=default")
    end

    if target:is_library() or target:values("swift.interop.cxxmain") then
        target:add("scflags", "-parse-as-library")
    end
    local modulename = target:values("swift.modulename") or target:name()
    target:add("scflags", "-module-name", modulename, {force = true})
    -- we use swift-frontend to support multiple modules
    -- @see https://github.com/xmake-io/xmake/issues/3916
    if target:has_tool("sc", "swift_frontend") then
        local sourcebatch = target:sourcebatches()["swift.build"]
        if sourcebatch then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                target:add("scflags", sourcefile, {force = true})
            end
        end
    end
end
