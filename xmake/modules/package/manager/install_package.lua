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
import("core.project.config")

-- install package
function _install_package(manager_name, package_name, opt)

    -- get managers
    if manager_name then
        dprint("installing %s from %s ..", package_name, manager_name)
        return import("package.manager." .. manager_name .. ".install_package", {anonymous = true})(package_name, opt)
    end

    -- get suitable package managers
    local managers = {}
    if is_host("windows") then
        table.insert(managers, "pacman") -- msys/mingw
    elseif is_host("linux") then
        table.insert(managers, "apt")
        table.insert(managers, "yum")
        table.insert(managers, "pacman")
        table.insert(managers, "brew")
    elseif is_host("macosx") then
        table.insert(managers, "vcpkg")
        table.insert(managers, "brew")
    end
    assert(#managers > 0, "no suitable package manager!")

    -- install package from the given package managers
    local errors = nil
    for _, manager in ipairs(managers) do

        -- trace
        dprint("installing %s from %s ..", package_name, manager)

        -- try to install it
        local ok = try
        {
            function ()
                import("package.manager." .. manager .. ".install_package", {anonymous = true})(package_name, opt)
                return true
            end,
            catch
            {
                function (errs)
                    errors = errs
                end
            }
        }

        -- install ok?
        if ok then
            dprint("install %s ok from %s", package_name, manager)
            return
        end
    end

    -- install failed
    raise("install %s failed! %s", package_name, errors or "")
end

-- install package using the package manager
--
-- @param name  the package name, e.g. zlib 1.12.x (try all), XMAKE::zlib 1.12.x, BREW::zlib, VCPKG::zlib, CONAN::OpenSSL/1.0.2n@conan/stable
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- get the copied options
    opt = table.copy(opt)
    opt.plat = opt.plat or config.get("plat") or os.host()
    opt.arch = opt.arch or config.get("arch") or os.arch()
    opt.mode = opt.mode or config.mode() or "release"

    -- get package manager name
    local manager_name, package_name = unpack(name:split("::", {plain = true, strict = true}))
    if package_name == nil then
        package_name = manager_name
        manager_name = nil
    else
        manager_name = manager_name:lower():trim()
    end

    -- get package name and require version
    local require_version = nil
    package_name, require_version = unpack(package_name:trim():split("%s"))
    opt.version = require_version or opt.version

    -- do install package
    _install_package(manager_name, package_name, opt)
end
