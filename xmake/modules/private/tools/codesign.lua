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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        codesign.lua
--

-- imports
import("lib.detect.find_tool")

-- main entry
function main (programdir)

    -- get codesign
    local codesign = find_tool("codesign")
    if not codesign then
        return
    end

    -- get codesign_allocate
    local codesign_allocate
    local xcode_sdkdir = get_config("xcode")
    if xcode_sdkdir then
        codesign_allocate = path.join(xcode_sdkdir, "Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/codesign_allocate")
    end

    -- do sign
    local argv = {"--force", "--timestamp=none"}
    table.insert(argv, "--sign")
    table.insert(argv, "-")
    table.insert(argv, programdir)
    os.vrunv(codesign.program, argv, {envs = {CODESIGN_ALLOCATE = codesign_allocate}})
end

