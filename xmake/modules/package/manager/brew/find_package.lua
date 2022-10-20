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
-- @file        find_package.lua
--

-- imports
import("lib.detect.find_tool")
import("lib.detect.find_file")
import("lib.detect.find_path")
import("lib.detect.pkgconfig")
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

-- find package from pkg-config
function _find_package_from_pkgconfig(name, opt)
    opt = opt or {}
    local brew_pkg_rootdir = opt.brew_pkg_rootdir

    -- parse name, e.g. pcre/libpcre16
    local nameinfo = name:split('/')
    local pcname   = nameinfo[2] or nameinfo[1]

    -- find package from pkg-config/*.pc, attempt to find it from `brew --prefix`/package first
    local result = nil
    local pcfile = find_file(pcname .. ".pc", path.join(brew_pkg_rootdir, nameinfo[1], "*/lib/pkgconfig")) or
                   find_file(pcname .. ".pc", path.join(brew_pkg_rootdir, nameinfo[1], "*/share/pkgconfig"))
    if not pcfile then
        -- attempt to find it from `brew --prefix package`
        local brew = find_tool("brew")
        local brew_pkgdir = brew and try {function () return os.iorunv(brew.program, {"--prefix", nameinfo[1]}) end}
        if brew_pkgdir then
            brew_pkgdir = brew_pkgdir:trim()
            pcfile = find_file(pcname .. ".pc", path.join(brew_pkgdir, "lib/pkgconfig")) or
                     find_file(pcname .. ".pc", path.join(brew_pkgdir, "share/pkgconfig"))
        end
    end
    if pcfile then
        opt.configdirs = path.directory(pcfile)
        result = find_package("pkgconfig::" .. pcname, opt)
        if not result or not result.includedirs then
            -- attempt to get includedir variable from pkg-config/xx.pc
            local varinfo = pkgconfig.variables(pcname, "includedir", opt)
            if varinfo and varinfo.includedir then
                result = result or {}
                result.version = pkgconfig.version(pcname, opt)
                result.includedirs = varinfo.includedir
            end
        end
    end
    return result
end

-- find package from the brew package manager
--
-- @param name  the package name, e.g. zlib, pcre/libpcre16
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- find the prefix directory of brew
    opt = opt or {}
    local brew_pkg_rootdir = _brew_pkg_rootdir()
    if not brew_pkg_rootdir then
        return
    end
    brew_pkg_rootdir = path.join(brew_pkg_rootdir, opt.plat == "macosx" and "Cellar" or "opt")

    -- find package from pkg-config
    local result = _find_package_from_pkgconfig(name,
        table.join(opt, {brew_pkg_rootdir = brew_pkg_rootdir}))

    -- find components
    local components
    local components_extsources = opt.components_extsources
    for _, comp in ipairs(opt.components) do
        local extsource = components_extsources and components_extsources[comp]
        if extsource then
            local component_result = _find_package_from_pkgconfig(extsource,
                table.join(opt, {brew_pkg_rootdir = brew_pkg_rootdir}))
            if component_result then
                components = components or {}
                components[comp] = component_result
            end
        end
    end
    if components then
        result = result or {}
        result.components = components
        components.__base = {}
    end

    -- find package from xxx/lib, xxx/include
    if not result then
        local nameinfo = name:split('/')
        local pkgdir = find_path("lib", path.join(brew_pkg_rootdir, nameinfo[1], "*"))
        if pkgdir then
            local links = {}
            for _, libfile in ipairs(os.files(path.join(pkgdir, "lib", "*.a"))) do
                table.insert(links, target.linkname(path.filename(libfile), {plat = opt.plat}))
            end
            for _, libfile in ipairs(os.files(path.join(pkgdir, "lib", opt.plat == "macosx" and "*.dylib" or "*.so"))) do
                if not os.islink(libfile) then
                    table.insert(links, target.linkname(path.filename(libfile), {plat = opt.plat}))
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
