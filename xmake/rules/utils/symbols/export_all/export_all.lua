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
-- @file        export_all.lua
--

-- imports
import("lib.detect.find_tool")
import("core.tool.toolchain")

-- export all symbols for dynamic library
function main (target)
    -- @note it only supports windows/dll now
    assert(target:kind() == "shared", 'rule("utils.symbols.export_all"): only for shared target!')
    if not target:is_plat("windows") then
        return
    end

    -- get dumpbin
    local msvc = toolchain.load("msvc", {plat = target:plat(), arch = target:arch()})
    local dumpbin = assert(find_tool("dumpbin", {envs = msvc:runenvs()}), "dumpbin not found!")

    -- export all symbols
    local allsymbols_filepath = path.join(target:autogendir(), "rules", "symbols", "export_all.def")
    local allsymbols_file = io.open(allsymbols_filepath, 'w')
    allsymbols_file:print("EXPORTS")
    for _, objectfile in ipairs(target:objectfiles()) do
        local objectsymbols = os.iorunv(dumpbin.program, {"/symbols", "/nologo", objectfile})
        if objectsymbols then
            for _, line in ipairs(objectsymbols:split('\n', {plain = true})) do
                -- 008 00000000 SECT3  notype ()    External     | add
                if line:find("External") then
                    local symbol = line:match(".*External%s+| (.*)")
                    if symbol then
                        symbol = symbol:trim()
                        allsymbols_file:print("%s", symbol)
                    end
                end
            end
        end
    end
    allsymbols_file:close()
    target:add("shflags", "/def:" .. allsymbols_filepath, {force = true})
end
