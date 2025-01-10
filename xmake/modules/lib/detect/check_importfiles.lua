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
-- @file        check_importfiles.lua
--

-- imports
import("core.base.option")
import("lib.detect.pkgconfig")
import("package.manager.cmake.find_package", {alias = "cmake_find_package"})

-- check the given importfiles for pkgconfig/cmake
--
-- @param names the import filenames (without .pc/.cmake suffix), e.g. pkgconfig::libxml-2.0, cmake::CURL
-- @param opt   the argument options, e.g. { verbose = true, configdirs = {"lib"}}
--
function main(names, opt)
    local verbose
    if opt.verbose or option.get("verbose") or option.get("diagnosis") then
        verbose = true
    end
    for _, name in ipairs(names) do
        local kind
        local parts = name:split("::")
        if #parts == 2 then
            kind = parts[1]
            name = parts[2]
        end
        if kind == nil then
            kind = "pkgconfig"
        end
        if verbose then
            cprint("${dim}> checking for %s/%s", kind, name)
        end
        if kind == "pkgconfig" then
            opt.configdirs = opt.PKG_CONFIG_PATH
            local result = pkgconfig.libinfo(name, opt)
            if verbose and result then
                print(result)
            end
            if not result then
                return false, string.format("pkgconfig/%s.pc not found!", name)
            end
        elseif kind == "cmake" then
            if opt.CMAKE_PREFIX_PATH then
                opt.configs = opt.configs or {}
                opt.configs.envs = opt.configs.envs or {}
                opt.configs.envs.CMAKE_PREFIX_PATH = path.joinenv(table.wrap(opt.CMAKE_PREFIX_PATH))
            end
            local result = cmake_find_package(name, opt)
            if verbose and result then
                print(result)
            end
            if not result then
                return false, string.format("cmake/%s.cmake not found!", name)
            end
        end
    end
    return true
end

