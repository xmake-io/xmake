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
-- @file        depend.lua
--

-- imports
import("core.base.option")
import("core.tool.toolchain")
import("lib.detect.find_tool")

function _get_all_depends_by_dumpbin(binaryfile, opt)
    local depends
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    local msvc = toolchain.load("msvc", {plat = plat, arch = arch})
    if msvc:check() then
        local dumpbin = find_tool("dumpbin", {cachekey = "utils.symbols.depend", envs = msvc:runenvs()})
        if dumpbin then
            local binarydir = path.directory(binaryfile)
            local result = try { function () return os.iorunv(dumpbin.program, {"/dependents", "/nologo", binaryfile}) end }
            if result then
                for _, line in ipairs(result:split("\n")) do
                    line = line:trim()
                    if line:endswith(".dll") then
                        local dependfile
                        if os.isfile(line) then
                            dependfile = line
                        elseif os.isfile(path.join(binarydir, line)) then
                            dependfile = path.join(binarydir, line)
                        end
                        if dependfile then
                            depends = depends or {}
                            table.insert(depends, path.absolute(dependfile))
                        end
                    end
                end
            end
        end
    end
    return depends
end

function _get_all_depends_by_objdump(binaryfile, opt)
    local depends
    local cachekey = "utils.symbols.depend"
    local objdump = find_tool("llvm-objdump", {cachekey = cachekey}) or find_tool("objdump", {cachekey = cachekey})
    if objdump then
        local binarydir = path.directory(binaryfile)
        local result = try { function () return os.iorunv(objdump.program, {"-p", binaryfile}) end }
        if result then
            for _, line in ipairs(result:split("\n")) do
                line = line:trim()
                if line:startswith("DLL Name:") then
                    local filename = line:split(":")[2]:trim()
                    if filename:endswith(".dll") then
                        local dependfile
                        if os.isfile(filename) then
                            dependfile = line
                        elseif os.isfile(path.join(binarydir, filename)) then
                            dependfile = path.join(binarydir, filename)
                        end
                        if dependfile then
                            depends = depends or {}
                            table.insert(depends, path.absolute(dependfile))
                        end
                    end
                end
            end
        end
    end
    return depends
end

function main(binaryfile, opt)
    opt = opt or {}
    local dumpers = {
        _get_all_depends_by_objdump
    }
    if is_host("windows") then
        table.insert(dumpers, _get_all_depends_by_dumpbin)
    end
    for _, dump in ipairs(dumpers) do
        local depends = dump(binaryfile, opt)
        if depends then
            return depends
        end
    end
end

