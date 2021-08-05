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
-- @file        find_vcpkgdir.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.cache.detectcache")
import("lib.detect.find_tool")

-- find vcpkgdir
function main()
    local vcpkgdir = detectcache:get("detect.sdks.find_vcpkgdir")
    if vcpkgdir == nil then
        if not vcpkgdir then
            vcpkgdir = config.get("vcpkg") or global.get("vcpkg")
            if vcpkgdir then
                if os.isfile(vcpkgdir) then
                    vcpkgdir = path.directory(vcpkgdir)
                end
            end
        end
        if not vcpkgdir then
            vcpkgdir = os.getenv("VCPKG_ROOT") or os.getenv("VCPKG_INSTALLATION_ROOT")
        end
        if not vcpkgdir and is_host("macosx", "linux") then
            local brew = find_tool("brew")
            if brew then
                dir = try
                {
                    function ()
                        return os.iorunv(brew.program, {"--prefix", "vcpkg"})
                    end
                }
            end
            if dir then
                dir = path.join(dir:trim(), "libexec")
                if os.isdir(path.join(dir, "installed")) then
                    vcpkgdir = dir
                end
            end
        end
        if not vcpkgdir and is_host("windows") then
            -- attempt to read path info after running `vcpkg integrate install`
            local pathfile = "~/../Local/vcpkg/vcpkg.path.txt"
            if os.isfile(pathfile) then
                local dir = io.readfile(pathfile):trim()
                if os.isdir(dir) then
                    vcpkgdir = dir
                end
            end
        end
        detectcache:set("detect.sdks.find_vcpkgdir", vcpkgdir or false)
        detectcache:save()
    end
    return vcpkgdir or nil
end
