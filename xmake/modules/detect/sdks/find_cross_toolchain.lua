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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
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
    table.insert(bindirs, path.join(sdkdir, "**", "bin"))

    -- attempt to find *-ld
    local ldname = is_host("windows") and "ld.exe" or "ld"
    local ldpath = find_file((opt.cross or '*-') .. ldname, bindirs)
    if ldpath then
        return path.directory(ldpath), path.basename(ldpath):sub(1, -3)
    end
    
    -- find ld
    ldpath = find_file(ldname, bindirs)
    if ldpath then
        return path.directory(ldpath), ""
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

    -- get root directory
    if not sdkdir or not os.isdir(sdkdir) then
        return 
    end

    -- find bin directory and cross
    local bindir, cross = _find_bindir(sdkdir, opt)
    if not bindir then
        return 
    end

    -- found
    return {sdkdir = sdkdir, bindir = bindir, cross = cross}
end
