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

-- split full package name into manager, package and version strings
--
-- @param name  the package name
--              e.g. zlib 1.12.x (try all), xmake::zlib 1.12.x, brew::zlib, brew::pcre/libpcre16, vcpkg::zlib, conan::OpenSSL/1.0.2n@conan/stable
--
-- @return      manager, package, version
--              e.g. "xmake", "zlib", "1.12.x"
--
-- @code
--
-- local manager, package, version = split_package_name("xmake::zlib 1.12.x")
--
-- @endcode
--

function main(name)

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

    return manager_name, package_name, require_version
end