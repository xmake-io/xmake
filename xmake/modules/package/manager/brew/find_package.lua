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
-- @file        find_package.lua
--

-- imports
import("lib.detect.find_tool")
import("lib.detect.find_file")
import("lib.detect.find_path")
import("lib.detect.pkg_config")
import("core.project.target")
import("package.manager.find_package")

-- get the root directory of the brew packages
function _brew_pkg_rootdir()
    local brew_pkg_rootdir = _g.brew_pkg_rootdir
    if brew_pkg_rootdir == nil then
        local brew = find_tool("brew")
        if brew then
            brew_pkg_rootdir = try
            {
                function ()
                    return os.iorunv(brew.program, {"--prefix"})
                end
            } or "/usr/local"
        end
        if brew_pkg_rootdir then
            brew_pkg_rootdir = brew_pkg_rootdir:trim()
        end
        _g.brew_pkg_rootdir = brew_pkg_rootdir or false
    end
    return brew_pkg_rootdir or nil
end

-- find package from the brew package manager
--
-- @param name  the package name, e.g. zlib, pcre/libpcre16
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- find the prefix directory of brew
    local brew_pkg_rootdir = _brew_pkg_rootdir()
    if not brew_pkg_rootdir then
        return
    end
    brew_pkg_rootdir = path.join(brew_pkg_rootdir, opt.plat == "macosx" and "Cellar" or "opt")

    -- parse name, e.g. pcre/libpcre16
    local nameinfo = name:split('/')
    local pcname   = nameinfo[2] or nameinfo[1]

    -- find package from pkg-config/*.pc
    local result = nil
    local pcfile = find_file(pcname .. ".pc", path.join(brew_pkg_rootdir, nameinfo[1], "*/lib/pkgconfig"))
    if pcfile then
        opt.configdirs = path.directory(pcfile)
        result = find_package("pkg_config::" .. pcname, opt)
        if not result then
            -- attempt to get includedir variable from pkg-config/xx.pc
            local varinfo = pkg_config.variables(pcname, "includedir", opt)
            if varinfo and varinfo.includedir then
                result = result or {}
                result.version = pkg_config.version(pcname, opt)
                result.includedirs = varinfo.includedir
            end
        end
    end

    -- find package from xxx/lib, xxx/include
    if not result then
        local pkgdir = find_path("lib", path.join(brew_pkg_rootdir, nameinfo[1], "*"))
        if pkgdir then
            local links = {}
            for _, libfile in ipairs(os.files(path.join(pkgdir, "lib", "*.a"))) do
                table.insert(links, target.linkname(path.filename(libfile)))
            end
            for _, libfile in ipairs(os.files(path.join(pkgdir, "lib", opt.plat == "macosx" and "*.dylib" or "*.so"))) do
                if not os.islink(libfile) then
                    table.insert(links, target.linkname(path.filename(libfile)))
                end
            end
            opt.links       = links
            opt.linkdirs    = path.join(pkgdir, "lib")
            opt.includedirs = path.join(pkgdir, "include")
            result = find_package("system::" .. name, opt)
        end
    end
    return result
end
