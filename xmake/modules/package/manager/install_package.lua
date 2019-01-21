--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
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
-- @file        install_package.lua
--

-- install package 
function _install_package(manager_name, package_name, opt)

    -- get managers
    local managers = {}
    if manager_name then
        table.insert(managers, manager_name)
    else 
        if is_host("windows") then
            table.insert(managers, "pacman") -- msys/mingw
        elseif is_host("linux") then
            table.insert(managers, "apt")
            table.insert(managers, "yum")
            table.insert(managers, "pacman")
            table.insert(managers, "brew")
        elseif is_host("macosx") then
            table.insert(managers, "brew")
        end
    end
    assert(#managers > 0, "no suitable package manager!")

    -- find package from the given package manager
    for _, manager_name in ipairs(managers) do
        dprint("installing %s from %s ..", package_name, manager_name)
        if import("package.manager." .. manager_name .. ".install_package", {anonymous = true})(package_name, opt) then
            break
        end
    end
end

-- install package using the package manager
--
-- @param name  the package name, e.g. zlib 1.12.x (try all), XMAKE::zlib 1.12.x, BREW::zlib, VCPKG::zlib, CONAN::OpenSSL/1.0.2n@conan/stable
-- @param opt   the options, .e.g {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- get the copied options
    opt = table.copy(opt)

    -- get package manager name
    local manager_name, package_name = unpack(name:split("::", true))
    if package_name == nil then
        package_name = manager_name
        manager_name = nil
    else
        manager_name = manager_name:lower():trim()
    end

    -- get package name and require version
    local require_version = nil
    package_name, require_version = unpack(package_name:trim():split("%s+"))
    opt.version = require_version or opt.version

    -- do install package
    _install_package(manager_name, package_name, opt)
end
