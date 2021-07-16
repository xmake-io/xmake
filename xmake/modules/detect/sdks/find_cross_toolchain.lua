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
-- @file        find_cross_toolchain.lua
--

-- imports
import("core.project.config")
import("lib.detect.find_file")

-- find bin directory and cross
function _find_bindir(sdkdir, opt)

    -- init bin directories
    local bindirs = {}
    if opt.bindir then
        table.insert(bindirs, opt.bindir)
    end
    table.insert(bindirs, path.join(sdkdir, "bin"))

    -- attempt to find *-[gcc|clang|ld]
    for _, toolname in ipairs({"gcc", "clang", "ld"}) do
        if is_host("windows") then
            toolname = toolname .. ".exe"
        end
        local toolpath = find_file((opt.cross or '*-') .. toolname, bindirs)
        if toolpath then
            return path.directory(toolpath), path.filename(toolpath):sub(1, -(#toolname + 1))
        end

        -- find tool path
        if not opt.cross then
            toolpath = find_file(toolname, bindirs)
            if toolpath then
                return path.directory(toolpath), ""
            end
        end
    end

    -- attempt to use the bin directory
    local bindir = opt.bindir or path.join(sdkdir, "bin")
    if os.isdir(bindir) and not opt.cross then
        return bindir
    end
end

-- find cross toolchain
--
-- @param sdkdir   the root sdk directory of cross toolchain
-- @param opt      the argument options
--                 e.g. {bindir = .., cross = ..}
--
-- @return          the toolchain e.g. {sdkdir = .., bindir = .., cross = ..}
--
-- @code
--
-- local toolchain = find_cross_toolchain("/xxx/android-cross-r10e")
-- local toolchain = find_cross_toolchain("/xxx/android-cross-r10e", {cross = "arm-linux-androideabi-"})
-- local toolchain = find_cross_toolchain("/xxx/android-cross-r10e", {cross = "arm-linux-androideabi-", bindir = ..})
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- get sdk directories
    local sdkdirs = {}
    if sdkdir then
        table.insert(sdkdirs, sdkdir)
    elseif opt.cross and not is_subhost("windows") then
        -- we attempt to find cross toolchain from /usr, e.g. /usr/bin/aarch64-linux-gnu-gcc
        table.insert(sdkdirs, "/usr/")
        table.insert(sdkdirs, "/usr/local")
    end

    -- find bin directory and cross
    local result
    for _, _sdkdir in ipairs(sdkdirs) do
        if os.isdir(_sdkdir) then
            local bindir, cross = _find_bindir(_sdkdir, opt)
            if bindir then
                result = {sdkdir = _sdkdir, bindir = bindir, cross = cross}
                break
            end
        end
    end
    return result
end
