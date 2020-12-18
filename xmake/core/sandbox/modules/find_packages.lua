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
-- @file        find_packages.lua
--

-- return module
return function (...)

    -- get find_package
    local find_package = require("sandbox/modules/import/core/sandbox/module").import("lib.detect.find_package", {anonymous = true})

    -- get packages and options
    local pkgs = {...}
    local opts = pkgs[#pkgs]
    if type(opts) == "table" then
        pkgs = table.slice(pkgs, 1, #pkgs - 1)
    else
        opts = {}
    end

    -- find all packages
    local packages = {}
    for _, pkgname in ipairs(pkgs) do
        local pkg = find_package(pkgname, opts)
        if pkg then
            table.insert(packages, pkg)
        end
    end
    return packages
end

