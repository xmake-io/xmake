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

-- export all symbols for windows/dll
--
-- @note: we don't need any export macros to a classes or functions!
-- and we can't use /GL (Whole Program Optimization) when use this approach!
--
-- @see https://github.com/xmake-io/xmake/issues/1123
--
rule("utils.symbols.export_all")
    on_load(function (target)
        -- @note it only supports windows/dll now
        assert(target:is_shared(), 'rule("utils.symbols.export_all"): only for shared target(%s)!', target:name())
        if target:is_plat("windows") then
            assert(target:get("optimize") ~= "smallest", 'rule("utils.symbols.export_all"): does not support set_optimize("smallest") for target(%s)!', target:name())
            local allsymbols_filepath = path.join(target:autogendir(), "rules", "symbols", "export_all.def")
            target:add("shflags", "/def:" .. allsymbols_filepath, {force = true})
        end
    end)
    before_link("export_all")

