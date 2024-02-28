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
-- @file        executable_path.lua
--

-- get executable file path
--
-- e.g.
-- "/usr/bin/xcrun -sdk macosx clang" -> "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
--
-- @see
-- https://github.com/xmake-io/xmake/issues/3159
-- https://github.com/xmake-io/xmake/issues/3286
-- https://github.com/xmake-io/xmake-repo/pull/1840#issuecomment-1434096993
function main(program)
    local program_map = _g.program_map
    if program_map == nil then
        program_map = {}
        _g.program_map = program_map
    end
    local filepath = program_map[program]
    if filepath then
        return filepath
    end
    if is_host("macosx") and program:find("xcrun -sdk", 1, true) then
        local cmd = program:gsub("xcrun %-sdk (%S+) (%S+)", function (plat, cc)
            return "xcrun -sdk " .. plat .. " -f " .. cc
        end)
        local splitinfo = cmd:split("%s")
        local result = try {function() return os.iorunv(splitinfo[1], table.slice(splitinfo, 2) or {}) end}
        if result then
            result = result:trim()
            if #result > 0 then
                filepath = result
            end
        end
    end
    -- patch .exe
    -- @see https://github.com/xmake-io/xmake/discussions/4781
    if is_host("windows") and path.is_absolute(program) then
        local program_exe = program .. ".exe"
        if os.isfile(program_exe) then
            program = program_exe
        end
    end
    if not filepath then
        filepath = program
    end
    program_map[program] = filepath
    return filepath
end
