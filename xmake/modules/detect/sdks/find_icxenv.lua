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
-- @file        find_icxenv.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_tool")

-- find intel c/c++ envirnoment on windows
function _find_intel_on_windows(opt)
end

-- find intel c/c++ envirnoment on linux
function _find_intel_on_linux(opt)

    -- attempt to find the sdk directory
    local oneapi_rootdirs = {"~/intel/oneapi/compiler", "/opt/intel/oneapi/compiler"}
    paths = {}
    for _, rootdir in ipairs(oneapi_rootdirs) do
        table.insert(paths, path.join(rootdir, "*", is_host("macosx") and "mac" or "linux", "bin"))
    end
    if #paths > 0 then
        local icx = find_file("icx", paths)
        if icx then
            local bindir = path.directory(icx)
            local sdkdir = path.directory(path.directory(bindir))
            return {sdkdir = sdkdir, bindir = bindir}
        end
    end
end

-- find intel c/c++ environment
function main(opt)
    if is_host("windows") then
        return _find_intel_on_windows(opt)
    else
        return _find_intel_on_linux(opt)
    end
end
