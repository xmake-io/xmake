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
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("detect.sdks.find_vcpkgdir")

-- install package
--
-- @param name  the package name, e.g. pcre2, pcre2/libpcre2-8
-- @param opt   the options, e.g. {verbose = true}
--
-- @return      true or false
--
function main(name, opt)

    -- attempt to find the vcpkg root directory
    local vcpkgdir = find_vcpkgdir(opt.vcpkgdir)
    if not vcpkgdir then
        raise("vcpkg not found!")
    end

    -- get arch, plat and mode
    local arch = opt.arch
    local plat = opt.plat
    local mode = opt.mode
    if plat == "macosx" then
        plat = "osx"
    end
    if arch == "x86_64" then
        arch = "x64"
    end

    -- init triplet
    local triplet = arch .. "-" .. plat
    if opt.plat == "windows" and opt.shared ~= true then
        triplet = triplet .. "-static"
        assert(not opt.vs_runtime or opt.vs_runtime:startswith("MT"), "only support static libraries with /MT[d] for vcpkg!")
    end

    -- init argv
    local argv = {"install", name .. ":" .. triplet}

    -- install package
    os.vrunv(path.join(vcpkgdir, "vcpkg"), argv)
end
