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
-- @file        pkgconfig_importfiles.lua
--

-- install pkgconfig/.pc import files
function main(target, opt)

    -- check
    opt = opt or {}
    assert(target:is_library(), 'pkgconfig_importfiles: only support for library target(%s)!', target:name())

    -- only for unix platform
    local installdir = target:installdir()
    if target:is_plat("windows") or not installdir then
        return
    end

    -- get pkgconfig/.pc file
    local pcfile = path.join(installdir, opt and opt.libdir or "lib", "pkgconfig", opt.filename or (target:basename() .. ".pc"))

    -- get includedirs
    local includedirs = opt.includedirs or {path.join(installdir, "include")}

    -- get links and linkdirs
    local links = opt.links or target:basename()
    local linkdirs = opt.linkdirs or {path.join(installdir, "lib")}

    -- get libs
    local libs = ""
    for _, linkdir in ipairs(linkdirs) do
        libs = libs .. "-L" .. linkdir
    end
    libs = libs .. " -L${libdir}"
    for _, link in ipairs(links) do
        libs = libs .. " -l" .. link
    end

    -- get cflags
    local cflags = ""
    for _, includedir in ipairs(includedirs) do
        cflags = cflags .. "-I" .. includedir
    end
    cflags = cflags .. " -I${includedir}"

    -- trace
    vprint("generating %s ..", pcfile)

    -- generate a *.pc file
    local file = io.open(pcfile, 'w')
    if file then
        file:print("prefix=%s", installdir)
        file:print("exec_prefix=${prefix}")
        file:print("libdir=${exec_prefix}/lib")
        file:print("includedir=${prefix}/include")
        file:print("")
        file:print("Name: %s", target:name())
        file:print("Description: %s", target:name())
        local version = target:get("version")
        if version then
            file:print("Version: %s", version)
        end
        file:print("Libs: %s", libs)
        file:print("Libs.private: ")
        file:print("Cflags: %s", cflags)
        file:close()
    end
end

