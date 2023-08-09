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
-- @author      w568w
-- @file        check_target.lua
--

-- imports
import("lib.detect.find_tool")

-- get rustc supported targets
--
-- @return          the supported target list. If rustc not found, return nil
function _get_rustc_supported_target()
    local rustc = find_tool("rustc")
    if not rustc then
        return nil
    end
    local output = os.iorunv(rustc.program, {"--print", "target-list"})
    return output:split('\n')
end

-- check whether the target is supported by rustc
--
-- @param arch      the target name, e.g. x86_64-unknown-linux-gnu
-- @param precise   whether to check the target precisely (i.e. check by rustc), otherwise only by syntax
--
-- @return          true if arch != nil and the target is supported by rustc, otherwise false
function main(arch, precise)

    if not arch then
        return false
    end

    -- 1: check by syntax
    local result = false
    local archs = arch:split("%-")
    if #archs >= 2 then
        result = true
    else
        wprint("the arch \"%s\" is NOT a valid target triple, will be IGNORED and may cause compilation errors, please check it again", arch)
    end

    -- 2: check by rustc
    if not precise then
        return result
    end
    result = false
    local rustc_supported_target = _get_rustc_supported_target()
    if rustc_supported_target then
        for _, v in ipairs(rustc_supported_target) do
            if v == arch then
                result = true
                break
            end
        end
        if not result then
            wprint("the arch \"%s\" is NOT supported by rustc, will be IGNORED and may cause compilation errors, please check it again", arch)
        end
    end

    return result
end
