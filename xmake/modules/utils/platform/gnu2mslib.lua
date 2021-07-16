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
-- @file        gnu2mslib.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.config")
import("core.tool.toolchain")
import("lib.detect.find_tool")

-- get .def file path from gnulib
function _get_defpath_from_gnulib(gnulib, msvc)

    -- check
    assert(os.isfile(gnulib), "%s not found!", gnulib)

    -- get dumpbin.exe
    local dumpbin = assert(find_tool("dumpbin", {envs = msvc:runenvs()}), "gnu2mslib(): dumpbin.exe not found!")

    -- get symbols
    local symbols_exported = hashset.new()
    local symbols = try {function() return os.iorunv(dumpbin.program, {"/linkermember", gnulib}) end}
    if symbols then
        local symbols_count
        local symbols_index = 0
        for _, line in ipairs(symbols:split('\n', {plain = true})) do
            if symbols_count == nil then
                symbols_count = line:match("(%d+) public symbols")
                if symbols_count then
                    symbols_count = tonumber(symbols_count)
                end
            else
                local symbol = line:match("%s+[%dABCDEF]+%s+(.+)")
                if symbol then
                    if not symbol:startswith("__") and not symbol:startswith("?") then
                        symbols_exported:insert(symbol)
                    end
                    symbols_index = symbols_index + 1
                    if symbols_index >= symbols_count then
                        break
                    end
                end
            end
        end
    end

    -- generate .def file
    if symbols_exported:size() > 0 then
        local defpath = os.tmpfile() .. ".def"
        local file = io.open(defpath, "w")
        file:print("EXPORTS")
        for _, symbol in ipairs(symbols_exported) do
            file:print("%s", symbol)
        end
        file:close()
        return defpath
    end
end

-- convert mingw/gnu xxx.dll.a to msvc xxx.lib
--
-- gnu2mslib(mslib, gnulib_or_defpath, {arch = "x64", dllname = "foo.dll"}
--
-- @see https://github.com/xmake-io/xmake/issues/1181
--
function main(mslib, gnulib_or_defpath, opt)

    -- check
    opt = opt or {}
    assert(is_host("windows"), "we can only run gnu2mslib() on windows!")
    assert(mslib and gnulib_or_defpath, "invalid input parameters, usage: gnu2mslib(mslib, gnulib_or_defpath, {arch = \"x64\", dllname = \"foo.dll\"})")

    -- get msvc toolchain
    local msvc = toolchain.load("msvc", {plat = opt.plat, arch = opt.arch})
    if not msvc:check() then
        raise("we can not get msvc toolchain!")
    end

    -- get lib.exe
    local libtool = assert(find_tool("lib", {envs = msvc:runenvs()}), "gnu2mslib(): lib.exe not found!")

    -- get dll name
    local dllname = opt.dllname or path.basename(mslib) .. ".dll"

    -- get def file path
    local defpath = gnulib_or_defpath:endswith(".def") and gnulib_or_defpath or _get_defpath_from_gnulib(gnulib_or_defpath, msvc)
    assert(defpath and os.isfile(defpath), "gnu2mslib(): convert failed, cannot get .def file!")

    -- generate mslib from gnulib
    os.vrunv(libtool.program, {"/def:" .. defpath, "/name:" .. path.filename(dllname), "/out:" .. mslib})

    -- remove temporary .def file
    if not gnulib_or_defpath:endswith(".def") then
        os.rm(defpath)
    end
end
