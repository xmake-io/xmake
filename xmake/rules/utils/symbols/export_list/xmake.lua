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

-- export the given symbols list
--
--@code
--  target("foo")
--    set_kind("shared")
--    add_files("src/foo.c")
--    add_rules("utils.symbols.export_list", {symbols = {
--      "add",
--      "sub"}})
--
--  target("foo2")
--    set_kind("shared")
--    add_files("src/foo.c")
--    add_files("src/foo.export.txt")
--    add_rules("utils.symbols.export_list")
--
rule("utils.symbols.export_list")
    set_extensions(".export.txt")
    on_config(function (target)
        assert(target:is_shared(), 'rule("utils.symbols.export_list"): only for shared target(%s)!', target:name())
        local exportfile
        local exportkind
        local exportsymbols = target:extraconf("rules", "utils.symbols.export_list", "symbols")
        if not exportsymbols then
            local sourcebatch = target:sourcebatches()["utils.symbols.export_list"]
            if sourcebatch then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    local list = io.readfile(sourcefile)
                    if list then
                        exportsymbols = list:split("\n")
                    end
                    break
                end
            end
        end
        assert(exportsymbols and #exportsymbols > 0, 'rule("utils.symbols.export_list"): no exported symbols!')
        local linkername = target:linker():name()
        if linkername == "dmd" then
            if target:is_plat("windows") then
                exportkind = "def"
                exportfile = path.join(target:autogendir(), "rules", "symbols", "export_list.def")
                target:add("shflags", "-L/def:" .. exportfile, {force = true})
            elseif target:is_plat("macosx", "iphoneos", "watchos", "appletvos") then
                exportkind = "apple"
                exportfile = path.join(target:autogendir(), "rules", "symbols", "export_list.exp")
                target:add("shflags", {"-L-exported_symbols_list", "-L" .. exportfile}, {force = true, expand = false})
            else
                exportkind = "ver"
                exportfile = path.join(target:autogendir(), "rules", "symbols", "export_list.map")
                target:add("shflags", "-L--version-script=" .. exportfile, {force = true})
            end
        elseif target:has_tool("ld", "link") then
            exportkind = "def"
            exportfile = path.join(target:autogendir(), "rules", "symbols", "export_list.def")
            target:add("shflags", "/def:" .. exportfile, {force = true})
        elseif target:is_plat("macosx", "iphoneos", "watchos", "appletvos") then
            exportkind = "apple"
            exportfile = path.join(target:autogendir(), "rules", "symbols", "export_list.exp")
            target:add("shflags", {"-Wl,-exported_symbols_list", exportfile}, {force = true, expand = false})
        elseif target:has_tool("ld", "gcc", "gxx", "clang", "clangxx") or
               target:has_tool("sh", "gcc", "gxx", "clang", "clangxx") then
            exportkind = "ver"
            exportfile = path.join(target:autogendir(), "rules", "symbols", "export_list.map")
            target:add("shflags", "-Wl,--version-script=" .. exportfile, {force = true})
        elseif target:has_tool("ld", "ld") or target:has_tool("sh", "ld") then
            exportkind = "ver"
            exportfile = path.join(target:autogendir(), "rules", "symbols", "export_list.map")
            target:add("shflags", "--version-script=" .. exportfile, {force = true})
        end
        if exportfile and exportkind then
            if exportkind == "ver" then
                io.writefile(exportfile, ([[{
    global:
        %s

    local:
        *;
};]]):format(table.concat(exportsymbols, ";\n        ") .. ";"))
            elseif exportkind == "apple" then
                local file = io.open(exportfile, 'w')
                for _, symbol in ipairs(exportsymbols) do
                    if not symbol:startswith("_") then
                        symbol = "_" .. symbol
                    end
                    file:print("%s", symbol)
                end
                file:close()
            elseif exportkind == "def" then
                local file = io.open(exportfile, 'w')
                file:print("EXPORTS")
                for _, symbol in ipairs(exportsymbols) do
                    file:print("%s", symbol)
                end
                file:close()
            end
        end
    end)

