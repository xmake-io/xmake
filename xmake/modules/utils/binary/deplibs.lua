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
-- @file        deplibs.lua
--

-- imports
import("core.base.option")
import("core.base.graph")
import("core.base.hashset")
import("core.tool.toolchain")
import("lib.detect.find_tool")
import("utils.binary.rpath", {alias = "rpath_utils"})

function _get_depends_by_dumpbin(binaryfile, opt)
    local depends
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    local cachekey = "utils.binary.deplibs"
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
                        depends = depends or {}
                        table.insert(depends, line)
                    end
                end
            end
        end
    end
    return depends
end

function _get_depends_by_objdump(binaryfile, opt)
    local depends
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    local cachekey = "utils.binary.deplibs"
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
                if not line:endswith(":") then
                    if plat == "windows" or plat == "mingw" then
                        if line:startswith("DLL Name:") then
                            local filename = line:split(":")[2]:trim()
                            if filename:endswith(".dll") then
                                depends = depends or {}
                                table.insert(depends, filename)
                            end
                        end
                    elseif plat == "macosx" or plat == "iphoneos" or plat == "appletvos" or plat == "watchos" then
                        local filename = line:match(".-%.dylib") or line:match(".-%.framework")
                        if filename then
                            depends = depends or {}
                            table.insert(depends, filename)
                        end
                    else
                        if line:startswith("NEEDED") then
                            local filename = line:split("%s+")[2]
                            if filename and filename:endswith(".so") or filename:find("%.so[%.%d+]+$") then
                                depends = depends or {}
                                table.insert(depends, filename)
                            end
                        end
                    end
                end
            end
        end
    end
    return depends
end

-- $ldd ./build/linux/x86_64/release/test
--	linux-vdso.so.1 (0x00007ffc51fdd000)
--	libfoo.so => /mnt/xmake/tests/projects/c/shared_library/./build/linux/x86_64/release/libfoo.so (0x00007fe241233000)
--	libstdc++.so.6 => /lib64/libstdc++.so.6 (0x00007fe240fca000)
--	libm.so.6 => /lib64/libm.so.6 (0x00007fe240ee7000)
--	libgcc_s.so.1 => /lib64/libgcc_s.so.1 (0x00007fe240eba000)
--	libc.so.6 => /lib64/libc.so.6 (0x00007fe240ccd000)
--	/lib64/ld-linux-x86-64.so.2 (0x00007fe24123a000)
--
function _get_depends_by_ldd(binaryfile, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "linux" and plat ~= "bsd" then
        return
    end
    local depends
    local cachekey = "utils.binary.deplibs"
    local ldd = find_tool("ldd", {cachekey = cachekey})
    if ldd then
        local binarydir = path.directory(binaryfile)
        local result = try { function () return os.iorunv(ldd.program, {binaryfile}) end }
        if result then
            for _, line in ipairs(result:split("\n")) do
                local splitinfo = line:split("=>")
                line = splitinfo[2]
                if not line or line:find("not found", 1, true) then
                    line = splitinfo[1]
                end
                line = line:gsub("%(.+%)", ""):trim()
                local filename = line:match(".-%.so$") or line:match(".-%.so[%.%d+]+$")
                if filename then
                    depends = depends or {}
                    table.insert(depends, filename:trim())
                end
            end
        end
    end
    return depends
end

-- $ readelf -d build/linux/x86_64/release/test
--
-- Dynamic section at offset 0x2db8 contains 29 entries:
--  Tag        Type                         Name/Value
-- 0x0000000000000001 (NEEDED)             Shared library: [libfoo.so]
-- 0x0000000000000001 (NEEDED)             Shared library: [libstdc++.so.6]
-- 0x0000000000000001 (NEEDED)             Shared library: [libm.so.6]
-- 0x0000000000000001 (NEEDED)             Shared library: [libgcc_s.so.1]
-- 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
-- 0x000000000000001d (RUNPATH)            Library runpath: [$ORIGIN]
function _get_depends_by_readelf(binaryfile, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "linux" and plat ~= "bsd" and plat ~= "android" and plat ~= "cross" then
        return
    end
    local depends
    local cachekey = "utils.binary.deplibs"
    local readelf = find_tool("readelf", {cachekey = cachekey})
    if readelf then
        local binarydir = path.directory(binaryfile)
        local result = try { function () return os.iorunv(readelf.program, {"-d", binaryfile}) end }
        if result then
            for _, line in ipairs(result:split("\n")) do
                if line:find("NEEDED", 1, true) then
                    local filename = line:match("Shared library: %[(.-)%]")
                    if filename then
                        depends = depends or {}
                        table.insert(depends, filename:trim())
                    end
                end
            end
        end
    end
    return depends
end

-- $ otool -L build/iphoneos/arm64/release/test
-- build/iphoneos/arm64/release/test:
--        @rpath/libfoo.dylib (compatibility version 0.0.0, current version 0.0.0)
--        /System/Library/Frameworks/Foundation.framework/Foundation (compatibility version 300.0.0, current version 2048.1.101)
--        /usr/lib/libobjc.A.dylib (compatibility version 1.0.0, current version 228.0.0)
--        /usr/lib/libc++.1.dylib (compatibility version 1.0.0, current version 1600.151.0)
--        /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1336.0.0)
--
function _get_depends_by_otool(binaryfile, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "macosx" and plat ~= "iphoneos" and plat ~= "appletvos" and plat ~= "watchos" then
        return
    end
    local depends
    local cachekey = "utils.binary.deplibs"
    local otool = find_tool("otool", {cachekey = cachekey})
    if otool then
        local binarydir = path.directory(binaryfile)
        local result = try { function () return os.iorunv(otool.program, {"-L", binaryfile}) end }
        if result then
            for _, line in ipairs(result:split("\n")) do
                line = line:trim()
                if not line:endswith(":") then
                    local filename = line:match(".-%.dylib") or line:match(".-%.framework")
                    if filename then
                        depends = depends or {}
                        table.insert(depends, filename:trim())
                    end
                end
            end
        end
    end
    return depends
end

function _get_depends(binaryfile, opt)
    opt = opt or {}
    local ops = {
        _get_depends_by_objdump,
        _get_depends_by_readelf
    }
    if is_host("windows") then
        table.insert(ops, 1, _get_depends_by_dumpbin)
    elseif is_host("linux", "bsd") then
        table.insert(ops, 1, _get_depends_by_ldd)
    elseif is_host("macosx") then
        table.insert(ops, 1, _get_depends_by_otool)
    end
    for _, op in ipairs(ops) do
        local depends = op(binaryfile, opt)
        if depends then
            return depends
        end
    end
end

-- resolve file path with @rpath, @loader_path, and $ORIGIN
function _resolve_filepath(binaryfile, dependfile, opt)
    local loaderfile = opt._loaderfile
    local resolve_hint_paths = opt.resolve_hint_paths
    if dependfile:startswith("@rpath/") then
        local rpathlist = opt._rpathlist
        if rpathlist == nil then
            rpathlist = rpath_utils.list(loaderfile)
            opt._rpathlist = rpathlist or false
        end
        if rpathlist then
            for _, rpath in ipairs(rpathlist) do
                local filepath = dependfile:replace("@rpath/", rpath .. "/", {plain = true})
                if os.isfile(filepath) then
                    dependfile = path.absolute(filepath)
                    break
                elseif filepath:startswith("@loader_path/") then
                    filepath = filepath:replace("@loader_path/", path.directory(loaderfile) .. "/", {plain = true})
                    if os.isfile(filepath) then
                        dependfile = path.absolute(filepath)
                        break
                    end
                elseif filepath:startswith("$ORIGIN/") then
                    filepath = filepath:replace("$ORIGIN/", path.directory(loaderfile) .. "/", {plain = true})
                    if os.isfile(filepath) then
                        dependfile = path.absolute(filepath)
                        break
                    end
                end
            end
        end
    end
    if not path.is_absolute(dependfile) then
        if os.isfile(dependfile) then
            dependfile = path.absolute(dependfile)
        elseif resolve_hint_paths then
            local filename = path.filename(dependfile)
            for _, filepath in ipairs(resolve_hint_paths) do
                if filename == path.filename(filepath) then
                    dependfile = path.absolute(filepath)
                    break
                end
            end
        end
    end
    dependfile = path.normalize(dependfile)
    if binaryfile ~= dependfile then
        return dependfile
    end
end

function _get_plain_depends(binaryfile, opt)
    opt = opt or {}
    local depends = _get_depends(binaryfile, opt)
    if depends and opt.resolve_path then
        local result = {}
        for _, dependfile in ipairs(depends) do
            dependfile = _resolve_filepath(binaryfile, dependfile, opt)
            if dependfile then
                table.insert(result, dependfile)
            end
        end
        depends = result
    end
    return depends
end

function _get_recursive_depends(binaryfile, dag, depends, opt)
    local dependfiles = _get_plain_depends(binaryfile, opt)
    if dependfiles then
        for _, dependfile in ipairs(dependfiles) do
            dag:add_edge(binaryfile, dependfile)
            if not depends:has(dependfile) then
                depends:insert(dependfile)
                if os.isfile(dependfile) then
                    _get_recursive_depends(dependfile, dag, depends, opt)
                end
            end
        end
    end
end

-- get the library dependencies of the give binary files
--
-- @param binaryfile the binary file
-- @param opt        the option, e.g. {recursive = false, resolve_path = true, resolve_hint_paths = {}}
--                      - recursive: recursively get all sub-dependencies, sorted by topology
--                      - resolve_path: try to resolve the file full path, e.g. @rpath, @loader_path, $ORIGIN, relative path ..
--                      - resolve_hint_paths: we can resolve and match path from them
--
function main(binaryfile, opt)
    opt = opt or {}
    if opt.resolve_path then
        opt._loaderfile = binaryfile
    end
    binaryfile = path.normalize(path.absolute(binaryfile))
    if opt.recursive then
        local dag = graph.new(true)
        _get_recursive_depends(binaryfile, dag, hashset.new(), opt)
        local depends, has_cycle = dag:topo_sort()
        if has_cycle then
            local files = {}
            local cycle = dag:find_cycle()
            if cycle then
                for _, file in ipairs(cycle) do
                    table.insert(files, file)
                end
                table.insert(files, binaryfile)
            end
            raise("deplibs(%s): circular library dependencies detected!\n%s", binaryfile, table.concat(files, "\n   -> "))
        end
        if depends and #depends > 1 then
            return table.slice(depends, 2)
        end
    else
        return _get_plain_depends(binaryfile, opt)
    end
end
