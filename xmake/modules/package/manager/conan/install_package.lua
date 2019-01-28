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

    -- trace
    dprint("generate conanfile.txt ..")

    -- get conan options and imports
    local options        = table.wrap(opt.options)
    local imports        = table.wrap(opt.imports)
    local build_requires = table.wrap(opt.build_requires)

    -- generate it
    io.writefile("conanfile.txt", ([[
[generators]
xmake
[requires]
%s
[options]
%s
[imports]
%s
[build_requires]
%s
    ]]):format(name, table.concat(options, "\n"), table.concat(imports, "\n"), table.concat(build_requires, "\n")))
end

-- install package
--
-- @param name  the package name, e.g. conan::OpenSSL/1.0.2n@conan/stable 
-- @param opt   the options, .e.g {verbose = true, mode = "release", plat = , arch = , build = "all", options = {}, imports = {}, build_requires = {}}
--
-- @return      true or false
--
function main(name, opt)

    -- find conan
    local conan = find_tool("conan")
    if not conan then
        return false
    end

    -- get build directory
    local buildir = _get_build_directory(name)

    -- clean the build directory
    os.tryrm(buildir)
    if not os.isdir(buildir) then
        os.mkdir(buildir)
    end

    -- enter build directory
    local oldir = os.cd(buildir)

    -- generate conanfile.txt
    _generate_conanfile(name, opt)

    -- install package
    local argv = {"install", "."}
    if opt.build then
        if opt.build == "all" then
            table.insert(argv, "--build")
        else
            table.insert(argv, "--build=" .. opt.build)
        end
    end
    os.vrunv(conan.program, argv)

    -- leave build directory
    os.cd(oldir)

    -- ok
    return true
end
