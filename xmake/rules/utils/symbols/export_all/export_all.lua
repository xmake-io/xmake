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
import("core.base.option")
import("core.base.hashset")
import("core.project.depend")
import("utils.progress")

-- export all symbols for dynamic library
function main (target, opt)

    -- @note it only supports windows/dll now
    assert(target:is_shared(), 'rule("utils.symbols.export_all"): only for shared target(%s)!', target:name())
    if not target:is_plat("windows") or option.get("dry-run") then
        return
    end

    -- export all symbols
    local allsymbols_filepath = path.join(target:autogendir(), "rules", "symbols", "export_all.def")
    local dependfile = allsymbols_filepath .. ".d"
    depend.on_changed(function ()

        -- trace progress info
        progress.show(opt.progress, "${color.build.target}exporting.$(mode) %s", path.filename(target:targetfile()))

        -- get dumpbin
        local msvc = toolchain.load("msvc", {plat = target:plat(), arch = target:arch()})
        local dumpbin = assert(find_tool("dumpbin", {envs = msvc:runenvs()}), "dumpbin not found!")

        -- export c++ class?
        local export_classes = target:extraconf("rules", "utils.symbols.export_all", "export_classes")

        -- get all symbols from object files
        local allsymbols = hashset.new()
        for _, objectfile in ipairs(target:objectfiles()) do
            local objectsymbols = try { function () return os.iorunv(dumpbin.program, {"/symbols", "/nologo", objectfile}) end }
            if objectsymbols then
                for _, line in ipairs(objectsymbols:split('\n', {plain = true})) do
                    -- https://docs.microsoft.com/en-us/cpp/build/reference/symbols
                    -- 008 00000000 SECT3  notype ()    External     | add
                    if line:find("External") and not line:find("UNDEF") then
                        local symbol = line:match(".*External%s+| (.*)")
                        if symbol then
                            symbol = symbol:split('%s')[1]
                            if not symbol:startswith("__") then
                                if target:is_arch("x86") and symbol:startswith("_") then
                                    symbol = symbol:sub(2)
                                end
                                if export_classes or not symbol:startswith("?") then
                                    if export_classes then
                                        if not symbol:startswith("??_G") and not symbol:startswith("??_E") then
                                            allsymbols:insert(symbol)
                                        end
                                    else
                                        allsymbols:insert(symbol)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- export all symbols
        if allsymbols:size() > 0 then
            local allsymbols_file = io.open(allsymbols_filepath, 'w')
            allsymbols_file:print("EXPORTS")
            for _, symbol in allsymbols:keys() do
                allsymbols_file:print("%s", symbol)
            end
            allsymbols_file:close()
        else
            wprint('rule("utils.symbols.export_all"): no symbols are exported for target(%s)!', target:name())
        end

    end, {dependfile = dependfile, files = target:objectfiles()})
end
