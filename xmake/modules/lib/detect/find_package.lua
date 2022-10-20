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
import("core.base.option")
import("core.project.config")
import("core.cache.detectcache")
import("package.manager.find_package")

-- concat packages
function _concat_packages(a, b)
    local result = table.copy(a)
    for k, v in pairs(b) do
        local o = result[k]
        if o ~= nil then
            v = table.join(o, v)
        end
        result[k] = v
    end
    for k, v in pairs(result) do
        if k == "links" then
            if type(v) == "table" and #v > 1 then
                -- we need ensure link orders when removing repeat values
                v = table.reverse_unique(v)
            end
        else
            v = table.unique(v)
        end
        result[k] = v
    end
    return result
end

-- find package using the package manager
--
-- @param name  the package name
--              e.g. zlib 1.12.x (try all), xmake::zlib 1.12.x, brew::zlib, brew::pcre/libpcre16, vcpkg::zlib, conan::OpenSSL/1.0.2n@conan/stable
-- @param opt   the options
--              e.g. { verbose = false, force = false, plat = "iphoneos", arch = "arm64", mode = "debug", require_version = "1.0.x", version = true,
--                     external = true, -- we use sysincludedirs instead of includedirs as results
--                     linkdirs = {"/usr/lib"}, includedirs = "/usr/include", links = {"ssl"}, includes = {"ssl.h"}
--                     packagedirs = {"/tmp/packages"}, system = true, cachekey = "xxxx"
--                     pkgconfigs = {..}}
--
-- @return      {links = {"ssl", "crypto", "z"}, linkdirs = {"/usr/local/lib"}, includedirs = {"/usr/local/include"}}
--
-- @code
--
-- local package = find_package("openssl")
-- local package = find_package("openssl", {require_version = "1.0.*", version = true})
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
    opt.mode = opt.mode or config.mode() or "release"

    -- init cache key
    local cachekey = "find_package_" .. opt.plat .. "_" .. opt.arch
    if opt.cachekey then
        cachekey = cachekey .. "_" .. opt.cachekey
    end

    -- init package key
    local packagekey = name
    if opt.buildhash then
        packagekey = packagekey .. "_" .. opt.buildhash
    end
    if opt.mode then
        packagekey = packagekey .. "_" .. opt.mode
    end
    if opt.require_version then
        packagekey = packagekey .. "_" .. opt.require_version
    end
    if opt.external then
        packagekey = packagekey .. "_external"
    end

    -- attempt to get result from cache first
    local result = detectcache:get2(cachekey, packagekey)
    if result == nil or opt.force then

        -- find package
        local found_manager_name, package_name
        result, found_manager_name, package_name = find_package(name, opt)

        -- use isystem?
        if result and result.includedirs and opt.external then
            result.sysincludedirs = result.includedirs
            result.includedirs = nil
            local components_base = result.components and result.components.__base
            if components_base then
                components_base.sysincludedirs = components_base.includedirs
                components_base.includedirs = nil
            end
        end

        -- cache result
        detectcache:set2(cachekey, packagekey, result and result or false)
        detectcache:save()

        -- trace
        if opt.verbose or option.get("verbose") then
            if result then

                -- only display manager of found package if the package we searched for
                -- did not specify a package manager
                local display_manager = name:find("::", 1, true) and "" or (found_manager_name or "") .. "::"
                local display_name = display_manager .. package_name
                cprint("checking for %s ... ${color.success}%s %s", name, display_name, result.version and result.version or "")
            else
                cprint("checking for %s ... ${color.nothing}${text.nothing}", name)
            end
        end
    end

    -- does not show version (default)? strip it
    if not opt.version and result then
        result.version = nil
    end

    -- register concat
    if result and type(result) == "table" then
        debug.setmetatable(result, {__concat = _concat_packages})
    end
    return result and result or nil
end
