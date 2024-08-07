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
-- @file        is_cross.lua
--

-- load modules
local os = require("base/os")

-- is cross-compilation?
function is_cross(plat, arch)
    plat = plat or os.subhost()
    arch = arch or os.subarch()
    local host_os = os.host()
    if host_os == "windows" then
        if plat == "windows" then
            local host_arch = os.arch()
            -- maybe cross-compilation for arm64 on x86/x64
            if (host_arch == "x86" or host_arch == "x64") and arch == "arm64" then
                return true
            -- maybe cross-compilation for x86/64 on arm64
            elseif host_arch == "arm64" and arch ~= "arm64" then
                return true
            end
            return false
        elseif plat == "mingw" then
            return false
        end
    end
    if plat ~= os.host() and plat ~= os.subhost() then
        return true
    end
    if arch ~= os.arch() and arch ~= os.subarch() then
        return true
    end
    return false
end

return is_cross
