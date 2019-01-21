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
-- @file        find_package.lua
--

-- imports
import("core.base.semver")
import("core.base.option")
import("core.project.config")
import("lib.detect.cache")

-- find package 
function _find_package(manager_name, package_name, opt)

    -- get managers
    local managers = {}
    if manager_name then
        table.insert(managers, manager_name)
    else 
        if not is_host("windows") then
            table.insert(managers, "brew")
        end
        table.insert(managers, "vcpkg")
        table.insert(managers, "conan")
    end
    assert(#managers > 0, "no suitable package manager!")

    -- find package from the given package manager
    for _, manager_name in ipairs(managers) do
        dprint("finding %s from %s ..", package_name, manager_name)
        local result = import("package.manager." .. manager_name .. ".find_package", {anonymous = true})(package_name, opt)
        if result then
            return result
        end
    end
end

-- find package using the package manager
--
-- @param name  the package name, e.g. zlib 1.12.x (try all), XMAKE::zlib 1.12.x, BREW::zlib, VCPKG::zlib, CONAN::OpenSSL/1.0.2n@conan/stable
-- @param opt   the options
--              e.g. { verbose = false, force = false, plat = "iphoneos", arch = "arm64", mode = "debug", version = "1.0.x", 
--                     linkdirs = {"/usr/lib"}, includedirs = "/usr/include", links = {"ssl"}, includes = {"ssl.h"}
--                     packagedirs = {"/tmp/packages"}, system = true, cachekey = "xxxx"}
--
-- @return      {links = {"ssl", "crypto", "z"}, linkdirs = {"/usr/local/lib"}, includedirs = {"/usr/local/include"}}
--
-- @code 
--
-- local package = find_package("openssl")
-- local package = find_package("openssl", {version = "1.0.*"})
-- local package = find_package("openssl", {plat = "iphoneos"})
-- local package = find_package("openssl", {linkdirs = {"/usr/lib", "/usr/local/lib"}, includedirs = "/usr/local/include", version = "1.0.1"})
-- local package = find_package("openssl", {linkdirs = {"/usr/lib", "/usr/local/lib", links = {"ssl", "crypto"}, includes = {"ssl.h"}})
-- 
-- @endcode
--
function main(name, opt)

    -- get the copied options
    opt = table.copy(opt)
    opt.plat = opt.plat or config.get("plat") or os.host()
    opt.arch = opt.arch or config.get("arch") or os.arch()

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

    -- init cache key
    local key = "find_package_" .. opt.plat .. "_" .. opt.arch
    if opt.version then
        key = key .. "_" .. opt.version
    end
    if opt.cachekey then
        key = key .. "_" .. opt.cachekey
    end
    if opt.mode then
        key = key .. "_" .. opt.mode
    end

    -- attempt to get result from cache first
    local cacheinfo = cache.load(key) 
    local result = cacheinfo[package_name]
    if result ~= nil and not opt.force then
        return result and result or nil
    end

    -- find package
    result = _find_package(manager_name, package_name, opt)

    -- match version?
    if opt.version and result then
        if not result.version or not semver.satisfies(result.version, opt.version) then
            result = nil
        end
    end

    -- cache result
    cacheinfo[package_name] = result and result or false
    cache.save(key, cacheinfo)

    -- trace
    if opt.verbose or option.get("verbose") then
        if result then
            cprint("checking for the %s ... ${color.success}%s", package_name, result.version and result.version or "${text.success}")
        else
            cprint("checking for the %s ... ${color.nothing}${text.nothing}", package_name)
        end
    end

    -- ok?
    return result
end
