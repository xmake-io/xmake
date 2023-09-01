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

rule("c51.binary")
    on_load(function (target)
        -- we disable checking flags for cross toolchain automatically
        target:set("policy", "check.auto_ignore_flags", false)
        target:set("policy", "check.auto_map_flags", false)

        -- set default output binary
        target:set("kind", "binary")
        if not target:get("extension") then
            target:set("extension", "")
        end
    end)

    after_link(function(target, opt)
        import("core.project.depend")
        import("lib.detect.find_tool")
        import("utils.progress")
        depend.on_changed(function()
            local oh = assert(find_tool("oh51"), "oh51 not found")
            os.iorunv(oh.program, {target:targetfile()})
            progress.show(opt.progress, "${color.build.target}generating.$(mode) %s", target:targetfile() .. ".hex")
        end, {files = {target:targetfile()}, changed = target:is_rebuilt()})
    end)
