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

-- It is not very accurate because some rules automatically
-- generate objectfiles and do not save the corresponding sourcefiles.
-- @see https://github.com/xmake-io/xmake/issues/5601
function _get_sourcefiles_map(target, sourcefiles_map)
    for _, sourcebatch in pairs(target:sourcebatches()) do
        for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local objectfiles = sourcebatch.objectfiles
            if objectfiles then
                local objectfile = objectfiles[idx]
                if objectfile then
                    sourcefiles_map[objectfile] = sourcefile
                end
            end
        end
    end
    local plaindeps = target:get("deps")
    if plaindeps then
        for _, depname in ipairs(plaindeps) do
            local dep = target:dep(depname)
            if dep and dep:is_object() then
                _get_sourcefiles_map(dep, sourcefiles_map)
            end
        end
    end
end

-- use dumpbin to get all symbols from object files
function _get_allsymbols_by_dumpbin(target, dumpbin, opt)
    opt = opt or {}
    local allsymbols = hashset.new()
    local export_classes = opt.export_classes
    local export_filter = opt.export_filter
    local sourcefiles_map = {}
    if export_filter then
        _get_sourcefiles_map(target, sourcefiles_map)
    end
    for _, objectfile in ipairs(target:objectfiles()) do
        local objectsymbols = try { function () return os.iorunv(dumpbin, {"/symbols", "/nologo", objectfile}) end }
        if objectsymbols then
            local sourcefile = sourcefiles_map[objectfile]
            for _, line in ipairs(objectsymbols:split('\n', {plain = true})) do
                -- https://docs.microsoft.com/en-us/cpp/build/reference/symbols
                -- 008 00000000 SECT3  notype ()    External     | add
                if line:find("External") and not line:find("UNDEF") then
                    local symbol = line:match(".*External%s+| (.*)")
                    if symbol then
                        symbol = symbol:split('%s')[1]
                        -- we need ignore DllMain, https://github.com/xmake-io/xmake/issues/3992
                        if target:is_arch("x86") and symbol:startswith("_") and not symbol:startswith("__") and not symbol:startswith("_DllMain@") then
                            symbol = symbol:sub(2)
                        end
                        if export_filter then
                            if export_filter(symbol, {objectfile = objectfile, sourcefile = sourcefile}) then
                                allsymbols:insert(symbol)
                            end
                        elseif not symbol:startswith("__") then
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
    return allsymbols
end

-- use objdump to get all symbols from object files
function _get_allsymbols_by_objdump(target, objdump, opt)
    opt = opt or {}
    local allsymbols = hashset.new()
    local export_classes = opt.export_classes
    local export_filter = opt.export_filter
    local sourcefiles_map = {}
    if export_filter then
        _get_sourcefiles_map(target, sourcefiles_map)
    end
    for _, objectfile in ipairs(target:objectfiles()) do
        local objectsymbols = try { function () return os.iorunv(objdump, {"--syms", objectfile}) end }
        if objectsymbols then
            local sourcefile = sourcefiles_map[objectfile]
            for _, line in ipairs(objectsymbols:split('\n', {plain = true})) do
                if line:find("(scl   2)", 1, true) then
                    local splitinfo = line:split("%s")
                    local symbol = splitinfo[#splitinfo]
                    if symbol then
                        -- we need ignore DllMain, https://github.com/xmake-io/xmake/issues/3992
                        if target:is_arch("x86") and symbol:startswith("_") and not symbol:startswith("__") and not symbol:startswith("_DllMain@") then
                            symbol = symbol:sub(2)
                        end
                        if export_filter then
                            if export_filter(symbol, {objectfile = objectfile, sourcefile = sourcefile}) then
                                allsymbols:insert(symbol)
                            end
                        elseif not symbol:startswith("__") then
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
    return allsymbols
end

-- export all symbols for dynamic library
function main(target, opt)

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

        -- export c++ class?
        local export_classes = target:extraconf("rules", "utils.symbols.export_all", "export_classes")

        -- the export filter
        local export_filter = target:extraconf("rules", "utils.symbols.export_all", "export_filter")

        -- get all symbols
        local allsymbols
        if target:has_tool("cc", "clang", "clang_cl", "clangxx", "gcc", "gxx") then
            local objdump = assert(find_tool("llvm-objdump") or find_tool("objdump"), "objdump not found!")
            allsymbols = _get_allsymbols_by_objdump(target, objdump.program, {
                export_classes = export_classes,
                export_filter = export_filter})
        end
        if not allsymbols then
            local msvc = toolchain.load("msvc", {plat = target:plat(), arch = target:arch()})
            if msvc:check() then
                local dumpbin = assert(find_tool("dumpbin", {envs = msvc:runenvs()}), "dumpbin not found!")
                allsymbols = _get_allsymbols_by_dumpbin(target, dumpbin.program, {
                    export_classes = export_classes,
                    export_filter = export_filter})
            end
        end

        -- export all symbols
        if allsymbols and allsymbols:size() > 0 then
            local allsymbols_file = io.open(allsymbols_filepath, 'w')
            allsymbols_file:print("EXPORTS")
            for _, symbol in allsymbols:keys() do
                allsymbols_file:print("%s", symbol)
            end
            allsymbols_file:close()
        else
            wprint('rule("utils.symbols.export_all"): no symbols are exported for target(%s)!', target:name())
        end

    end, {dependfile = dependfile, files = target:objectfiles(), changed = target:is_rebuilt()})
end

