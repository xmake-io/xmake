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
-- @file        goenv.lua
--

-- imports
import("lib.detect.find_tool")

function GOOS(plat)
    local goos
    if plat == "windows" or plat == "mingw" or plat == "msys" or plat == "cygwin" then
        goos = "windows"
    elseif plat == "linux" then
        goos = "linux"
    elseif plat == "macosx" then
        goos = "darwin"
    end
    return goos
end

function GOARCH(arch)
    return (arch == "x86" or arch == "i386") and "386" or "amd64"
end

function GOROOT(toolchain)
    local go = find_tool("go")
    if go then
        local gorootdir = try { function() return os.iorunv(go.program, {"env", "GOROOT"}) end }
        if gorootdir then
            return gorootdir:trim()
        end
    end
end
