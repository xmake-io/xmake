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
-- @file        rpath.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

function _replace_rpath_vars(rpath, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat == "macosx" or plat == "iphoneos" or plat == "appletvos" or plat == "watchos" then
        rpath = rpath:gsub("%$ORIGIN", "@loader_path")
    else
        rpath = rpath:gsub("@loader_path", "$ORIGIN")
        rpath = rpath:gsub("@executable_path", "$ORIGIN")
    end
    return rpath
end

function _get_rpath_list_by_objdump(binaryfile, opt)
    local list
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    local cachekey = "utils.binary.rpath"
    local objdump = find_tool("llvm-objdump", {cachekey = cachekey}) or find_tool("objdump", {cachekey = cachekey})
    if objdump then
        local binarydir = path.directory(binaryfile)
        local argv = {"-x", binaryfile}
        if plat == "macosx" or plat == "iphoneos" or plat == "appletvos" or plat == "watchos" then
            argv = {"--macho", "-x", binaryfile}
        end
        local result = try { function () return os.iorunv(objdump.program, argv) end }
        if result then
            local cmd = false
            for _, line in ipairs(result:split("\n")) do
                line = line:trim()
                if plat == "macosx" or plat == "iphoneos" or plat == "appletvos" or plat == "watchos" then
                    if not cmd and line:find("cmd LC_RPATH", 1, true) then
                        cmd = true
                    elseif cmd and (line:find("cmd ", 1, true) or line:find("Load command", 1, true)) then
                        cmd = false
                    end
                    if cmd then
                        local p = line:match("path (.-) %(")
                        if p then
                            list = list or {}
                            table.insert(list, p:trim())
                        end
                    end
                else
                    if line:startswith("RUNPATH") or line:startswith("RPATH") then
                        local p = line:split("%s+")[2]
                        if p then
                            list = list or {}
                            table.join2(list, path.splitenv(p:trim()))
                        end
                    end
                end
            end
        end
    end
    return list
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
-- ...
-- 0x000000000000000f (RPATH)              Library rpath: [$ORIGIN]
function _get_rpath_list_by_readelf(binaryfile, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "linux" and plat ~= "bsd" and plat ~= "android" and plat ~= "cross" then
        return
    end
    local list
    local cachekey = "utils.binary.rpath"
    local readelf = find_tool("readelf", {cachekey = cachekey})
    if readelf then
        local binarydir = path.directory(binaryfile)
        local result = try { function () return os.iorunv(readelf.program, {"-d", binaryfile}) end }
        if result then
            for _, line in ipairs(result:split("\n")) do
                if line:find("RUNPATH", 1, true) then
                    local p = line:match("Library runpath: %[(.-)%]")
                    if p then
                        list = list or {}
                        table.join2(list, path.splitenv(p:trim()))
                    end
                elseif line:find("RPATH", 1, true) then
                    local p = line:match("Library rpath: %[(.-)%]")
                    if p then
                        list = list or {}
                        table.join2(list, path.splitenv(p:trim()))
                    end
                end
            end
        end
    end
    return list
end

-- $ patchelf --print-rpath ./build/linux/x86_64/release/app
-- $ORIGIN:xxx:bar
function _get_rpath_list_by_patchelf(binaryfile, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "linux" and plat ~= "bsd" and plat ~= "android" and plat ~= "cross" then
        return
    end
    local list
    local cachekey = "utils.binary.rpath"
    local patchelf = find_tool("patchelf", {cachekey = cachekey})
    if patchelf then
        local binarydir = path.directory(binaryfile)
        local result = try { function () return os.iorunv(patchelf.program, {"--print-rpath", binaryfile}) end }
        if result then
            result = result:trim()
            if #result > 0 then
                list = path.splitenv(result)
            end
        end
    end
    return list
end


-- $ otool -l build/iphoneos/arm64/release/test
-- build/iphoneos/arm64/release/test:
--          cmd LC_RPATH
--      cmdsize 32
--         path @loader_path (offset 12)
--
function _get_rpath_list_by_otool(binaryfile, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "macosx" and plat ~= "iphoneos" and plat ~= "appletvos" and plat ~= "watchos" then
        return
    end
    local list
    local cachekey = "utils.binary.rpath"
    local otool = find_tool("otool", {cachekey = cachekey})
    if otool then
        local binarydir = path.directory(binaryfile)
        local result = try { function () return os.iorunv(otool.program, {"-l", binaryfile}) end }
        if result then
            local cmd = false
            for _, line in ipairs(result:split("\n")) do
                if not cmd and line:find("cmd LC_RPATH", 1, true) then
                    cmd = true
                elseif cmd and (line:find("cmd ", 1, true) or line:find("Load command", 1, true)) then
                    cmd = false
                end
                if cmd then
                    local p = line:match("path (.-) %(")
                    if p then
                        list = list or {}
                        table.insert(list, p:trim())
                    end
                end
            end
        end
    end
    return list
end

-- patchelf --add-rpath binaryfile
function _insert_rpath_by_patchelf(binaryfile, rpath, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "linux" and plat ~= "bsd" and plat ~= "android" and plat ~= "cross" then
        return false
    end
    local ok = try { function ()
        os.runv("patchelf", {"--add-rpath", rpath, binaryfile})
        return true
    end }
    return ok
end

-- install_name_tool -add_rpath <rpath> binaryfile
function _insert_rpath_by_install_name_tool(binaryfile, rpath, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "macosx" and plat ~= "iphoneos" and plat ~= "appletvos" and plat ~= "watchos" then
        return false
    end
    local ok = try { function ()
        os.vrunv("install_name_tool", {"-add_rpath", rpath, binaryfile})
        return true
    end }
    return ok
end

-- install_name_tool -rpath <rpath_old> <rpath_new> binaryfile
function _change_rpath_by_install_name_tool(binaryfile, rpath_old, rpath_new, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "macosx" and plat ~= "iphoneos" and plat ~= "appletvos" and plat ~= "watchos" then
        return false
    end
    local ok = try { function ()
        os.vrunv("install_name_tool", {"-rpath", rpath_old, rpath_new, binaryfile})
        return true
    end }
    return ok
end

-- use patchelf to remove the given rpath
function _remove_rpath_by_patchelf(binaryfile, rpath, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "linux" and plat ~= "bsd" and plat ~= "android" and plat ~= "cross" then
        return false
    end
    local ok = try { function ()
        local result = os.iorunv("patchelf", {"--print-rpath", binaryfile})
        if result then
            local rpaths_new = {}
            local removed = false
            for _, p in ipairs(path.splitenv(result:trim())) do
                if p ~= rpath then
                    table.insert(rpaths_new, p)
                else
                    removed = true
                end
            end
            if removed then
                if #rpaths_new > 0 then
                    os.runv("patchelf", {"--set-rpath", path.joinenv(rpaths_new), binaryfile})
                else
                    os.runv("patchelf", {"--remove-rpath", binaryfile})
                end
            end
        end
        return true
    end }
    return ok
end

-- install_name_tool -delete_rpath <rpath> binaryfile
function _remove_rpath_by_install_name_tool(binaryfile, rpath, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "macosx" and plat ~= "iphoneos" and plat ~= "appletvos" and plat ~= "watchos" then
        return false
    end
    local ok = try { function ()
        os.vrunv("install_name_tool", {"-delete_rpath", rpath, binaryfile})
        return true
    end }
    return ok
end

-- patchelf --remove-rpath binaryfile
function _clean_rpath_by_patchelf(binaryfile, opt)
    local plat = opt.plat or os.host()
    local arch = opt.arch or os.arch()
    if plat ~= "linux" and plat ~= "bsd" and plat ~= "android" and plat ~= "cross" then
        return false
    end
    local ok = try { function ()
        os.runv("patchelf", {"--remove-rpath", binaryfile})
        return true
    end }
    return ok
end

-- get rpath list
function list(binaryfile, opt)
    opt = opt or {}
    local ops = {
        _get_rpath_list_by_objdump,
        _get_rpath_list_by_readelf,
        _get_rpath_list_by_patchelf
    }
    if is_host("macosx") then
        table.insert(ops, 1, _get_rpath_list_by_otool)
    end
    for _, op in ipairs(ops) do
        local result = op(binaryfile, opt)
        if result then
            return result
        end
    end
end

-- insert rpath
function insert(binaryfile, rpath, opt)
    opt = opt or {}
    local ops = {
        _insert_rpath_by_patchelf
    }
    if is_host("macosx") then
        table.insert(ops, 1, _insert_rpath_by_install_name_tool)
    end
    rpath = _replace_rpath_vars(rpath, opt)
    local done = false
    for _, op in ipairs(ops) do
        if op(binaryfile, rpath, opt) then
            done = true
            break
        end
    end
    if not done then
        wprint("cannot insert rpath to %s, no rpath utility available, maybe we need to install patchelf", binaryfile)
    end
end

-- remove rpath
function remove(binaryfile, rpath, opt)
    opt = opt or {}
    local ops = {
        _remove_rpath_by_patchelf
    }
    if is_host("macosx") then
        table.insert(ops, 1, _remove_rpath_by_install_name_tool)
    end
    rpath = _replace_rpath_vars(rpath, opt)
    for _, op in ipairs(ops) do
        if op(binaryfile, rpath, opt) then
            break
        end
    end
end

-- change rpath
function change(binaryfile, rpath_old, rpath_new, opt)
    local function _change_rpath_by_generic(binaryfile, rpath_old, rpath_new, opt)
        remove(binaryfile, rpath_old, opt)
        insert(binaryfile, rpath_new, opt)
        return true
    end

    opt = opt or {}
    local ops = {
        _change_rpath_by_generic
    }
    if is_host("macosx") then
        table.insert(ops, 1, _change_rpath_by_install_name_tool)
    end
    rpath_old = _replace_rpath_vars(rpath_old, opt)
    rpath_new = _replace_rpath_vars(rpath_new, opt)
    local done = false
    for _, op in ipairs(ops) do
        if op(binaryfile, rpath_old, rpath_new, opt) then
            done = true
            break
        end
    end
    if not done then
        wprint("cannot change rpath to %s, no rpath utility available, maybe we need to install patchelf", binaryfile)
    end
end

-- clean rpath
function clean(binaryfile, opt)
    local function _clean_rpath_by_generic(binaryfile, opt)
        for _, rpath in ipairs(list(binaryfile, opt)) do
            remove(binaryfile, rpath, opt)
        end
        return true
    end

    opt = opt or {}
    local ops = {
        _clean_rpath_by_patchelf,
        _clean_rpath_by_generic
    }
    local done = false
    for _, op in ipairs(ops) do
        if op(binaryfile, opt) then
            done = true
            break
        end
    end
    if not done then
        wprint("cannot clean rpath %s, no rpath utility available, maybe we need to install patchelf", binaryfile)
    end
end
