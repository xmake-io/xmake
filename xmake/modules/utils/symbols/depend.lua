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
    local cachekey = "utils.symbols.depend"
    local msvc = toolchain.load("msvc", {plat = plat, arch = arch})
    if msvc:check() then
        local dumpbin = find_tool("dumpbin", {cachekey = cachekey, envs = msvc:runenvs()})
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
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    local cachekey = "utils.symbols.depend"
    local objdump = find_tool("llvm-objdump", {cachekey = cachekey}) or find_tool("objdump", {cachekey = cachekey})
    if objdump then
        local binarydir = path.directory(binaryfile)
        local argv = {"-p", binaryfile}
        if plat == "macosx" or plat == "iphoneos" or plat == "appletvos" or plat == "watchos" then
            argv = {"--macho", "--dylibs-used", binaryfile}
        end
        local result = try { function () return os.iorunv(objdump.program, argv) end }
        if result then
            for _, line in ipairs(result:split("\n")) do
                line = line:trim()
                if plat == "windows" or plat == "mingw" then
                    if line:startswith("DLL Name:") then
                        local filename = line:split(":")[2]:trim()
                        if filename:endswith(".dll") then
                            local dependfile
                            if os.isfile(filename) then
                                dependfile = filename
                            elseif os.isfile(path.join(binarydir, filename)) then
                                dependfile = path.join(binarydir, filename)
                            end
                            if dependfile then
                                depends = depends or {}
                                table.insert(depends, path.absolute(dependfile))
                            end
                        end
                    end
                elseif plat == "macosx" or plat == "iphoneos" or plat == "appletvos" or plat == "watchos" then
                    local filename = line:match(".-%.dylib") or line:match(".-%.framework")
                    if filename then
                        local dependfile
                        if os.exists(filename) then
                            dependfile = filename
                        elseif os.exists(path.join(binarydir, filename)) then
                            dependfile = path.join(binarydir, filename)
                        elseif filename:startswith("@rpath/") then -- TODO
                            filename = filename:sub(8)
                            if os.exists(path.join(binarydir, filename)) then
                                dependfile = path.join(binarydir, filename)
                            end
                        end
                        if dependfile then
                            depends = depends or {}
                            table.insert(depends, path.absolute(dependfile))
                        end
                    end
                else
                    if line:startswith("NEEDED") then
                        local filename = line:split("%s+")[2]
                        if filename and filename:endswith(".so") then
                            local dependfile
                            if os.isfile(filename) then
                                dependfile = filename
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
    end
    return depends
end

function _get_all_depends_by_ldd(binaryfile, opt)
end

function _get_all_depends_by_otool(binaryfile, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "macosx" and plat ~= "iphoneos" and plat ~= "appletvos" and plat ~= "watchos" then
        return
    end
    local depends
    local cachekey = "utils.symbols.depend"
    local otool = find_tool("otool", {cachekey = cachekey})
    if otool then
        local binarydir = path.directory(binaryfile)
        local result = try { function () return os.iorunv(otool.program, {"-L", binaryfile}) end }
        if result then
            for _, line in ipairs(result:split("\n")) do
                line = line:trim()
                local filename = line:match(".-%.dylib") or line:match(".-%.framework")
                if filename then
                    local dependfile
                    if os.exists(filename) then
                        dependfile = filename
                    elseif os.exists(path.join(binarydir, filename)) then
                        dependfile = path.join(binarydir, filename)
                    elseif filename:startswith("@rpath/") then -- TODO
                        filename = filename:sub(8)
                        if os.exists(path.join(binarydir, filename)) then
                            dependfile = path.join(binarydir, filename)
                        end
                    end
                    if dependfile then
                        depends = depends or {}
                        table.insert(depends, path.absolute(dependfile))
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
    elseif is_host("ldd") then
        table.insert(dumpers, _get_all_depends_by_ldd)
    elseif is_host("macosx") then
        table.insert(dumpers, _get_all_depends_by_otool)
    end
    for _, dump in ipairs(dumpers) do
        local depends = dump(binaryfile, opt)
        if depends then
            return depends
        end
    end
end

