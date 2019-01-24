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

-- imports
import("core.base.option")
import("core.project.config")
import("lib.detect.find_tool")

-- get build directory
function _get_build_directory(name)
    return path.join(config.buildir() or os.tmpdir(), ".conan", name)
end

-- generate conanfile.txt
function _generate_conanfile(name, opt)

    -- get conanfile.txt
    local conanfile = path.join(_get_build_directory(name), "conanfile.txt")

    -- trace
    dprint("generate %s ..", conanfile)

    -- get conan options and imports
    local conan_options = opt.conan_options or {}
    local conan_imports = opt.conan_imports or {}

    -- generate it
    io.writefile(conanfile, ([[
[generators]
xmake
[requires]
%s
[options]
%s
[imports]
%s
[build_requires]
xmake_generator/0.1.0@conan/xmakegen
    ]]):format(name, table.concat(conan_options, "\n"), table.concat(conan_imports, "\n")))
end

-- install package
--
-- @param name  the package name, e.g. conan::OpenSSL/1.0.2n@conan/stable 
-- @param opt   the options, .e.g {verbose = true, conan_options = {}, conan_imports = {}}
--
-- @return      true or false
--
function main(name, opt)

    -- find conan
    local conan = find_tool("conan")
    if not conan then
        return false
    end

    -- generate conanfile.txt
    _generate_conanfile(name, opt)

    -- ok
    return true
end
