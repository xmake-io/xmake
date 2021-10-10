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
import("core.base.semver")
import("core.base.option")
import("core.project.config")
import("lib.detect.find_tool")

-- find package with the builtin rule
--
-- opt.system:
--   nil: find local or system packages
--   true: only find system package
--   false: only find local packages
--
function _find_package_with_builtin_rule(package_name, opt)

    -- we cannot find it from xmake repo and package directories if only find system packages
    local managers = {}
    if opt.system ~= true then
        table.insert(managers, "xmake")
    end

    -- find system package if be not disabled
    if opt.system ~= false then

        -- find it from homebrew
        if not is_host("windows") then
            table.insert(managers, "brew")
        end

        -- find it from vcpkg (support multi-platforms/architectures)
        table.insert(managers, "vcpkg")

        -- find it from conan (support multi-platforms/architectures)
        table.insert(managers, "conan")

        -- only support the current sub-host platform and sub-architecture, e.g. linux, macosx, or msys (subsystem)
        if opt.plat == os.subhost() and opt.arch == os.subarch() then

            -- find it from pkg-config
            table.insert(managers, "pkgconfig")

            -- find it from pacman
            if is_subhost("linux", "msys") and not is_plat("windows") and find_tool("pacman") then
                table.insert(managers, "pacman")
            end

            -- find it from portage
            if is_subhost("linux", "msys") and not is_plat("windows") and find_tool("emerge") then
                table.insert(managers, "portage")
            end

            -- find it from system
            table.insert(managers, "system")
        end
    end

    -- find package from the given package manager
    local result = nil
    local found_manager_name = nil
    for _, manager_name in ipairs(managers) do
        dprint("finding %s from %s ..", package_name, manager_name)
        result = import("package.manager." .. manager_name .. ".find_package", {anonymous = true})(package_name, opt)
        if result then
            found_manager_name = manager_name
            break
        end
    end
    return result, found_manager_name
end

-- find package
function _find_package(manager_name, package_name, opt)

    -- find package from the given package manager
    local result = nil
    if manager_name then

        -- trace
        dprint("finding %s from %s ..", package_name, manager_name)

        -- TODO compatible with the previous version: pkg_config (deprecated)
        if manager_name == "pkg_config" then
            manager_name = "pkgconfig"
            wprint("please use find_package(\"pkgconfig::%s\") instead of `pkg_config::%s`", package_name, package_name)
        end

        -- find it
        result = import("package.manager." .. manager_name .. ".find_package", {anonymous = true})(package_name, opt)
    else

        -- find package from the given custom "detect.packages.find_xxx" script
        local builtin = false
        local find_package = import("detect.packages.find_" .. package_name, {anonymous = true, try = true})
        if find_package then

            -- trace
            dprint("finding %s from find_%s ..", package_name, package_name)

            -- find it
            result = find_package(table.join(opt, { find_package = function (...)
                                                        builtin = true
                                                        return _find_package_with_builtin_rule(...)
                                                    end}))
        end

        -- find package with the builtin rule
        if not result and not builtin then
            result, manager_name = _find_package_with_builtin_rule(package_name, opt)
        end
    end

    -- found?
    if result then

        -- remove repeat
        result.linkdirs    = table.unique(result.linkdirs)
        result.includedirs = table.unique(result.includedirs)
    end

    -- ok?
    return result, manager_name
end

-- find package using the package manager
--
-- @param name  the package name
--              e.g. zlib 1.12.x (try all), xmake::zlib 1.12.x, brew::zlib, brew::pcre/libpcre16, vcpkg::zlib, conan::OpenSSL/1.0.2n@conan/stable
-- @param opt   the options
--              e.g. { verbose = false, force = false, plat = "iphoneos", arch = "arm64", mode = "debug", version = "1.0.x",
--                     linkdirs = {"/usr/lib"}, includedirs = "/usr/include", links = {"ssl"}, includes = {"ssl.h"}
--                     packagedirs = {"/tmp/packages"}, system = true}
--
-- @return      {links = {"ssl", "crypto", "z"}, linkdirs = {"/usr/local/lib"}, includedirs = {"/usr/local/include"}},
--              manager_name, package_name
--
-- @code
--
-- local package = find_package("openssl")
-- local package = find_package("openssl", {require_version = "1.0.*"})
-- local package = find_package("openssl", {plat = "iphoneos"})
-- local package = find_package("openssl", {linkdirs = {"/usr/lib", "/usr/local/lib"}, includedirs = "/usr/local/include", require_version = "1.0.1"})
-- local package = find_package("openssl", {linkdirs = {"/usr/lib", "/usr/local/lib", links = {"ssl", "crypto"}, includes = {"ssl.h"}})
-- local package, manager_name, package_name = find_package("openssl")
--
-- @endcode
--

function main(name, opt)

    -- get the copied options
    opt = table.copy(opt)
    opt.plat = opt.plat or config.get("plat") or os.host()
    opt.arch = opt.arch or config.get("arch") or os.arch()
    opt.mode = opt.mode or config.mode() or "release"

    -- get package manager name
    local manager_name, package_name = table.unpack(name:split("::", {plain = true, strict = true}))
    if package_name == nil then
        package_name = manager_name
        manager_name = nil
    else
        manager_name = manager_name:lower():trim()
    end

    -- get package name and require version
    local require_version = nil
    package_name, require_version = table.unpack(package_name:trim():split("%s"))
    opt.require_version = require_version or opt.require_version

    -- find package
    local found_manager_name = nil
    result, found_manager_name = _find_package(manager_name, package_name, opt)

    -- match version?
    if opt.require_version and opt.require_version:find('.', 1, true) and result then
        if not (result.version and (result.version == opt.require_version or semver.satisfies(result.version, opt.require_version))) then
            result = nil
        end
    end
    return result, found_manager_name, package_name
end
