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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        environment.lua
--

-- imports
import("core.project.config")
import("core.platform.environment")
import("core.package.package", {alias = "core_package"})
import("lib.detect.find_tool")
import("package")

-- enter environment
--
-- ensure that we can find some basic tools: git, make/nmake/cmake, msbuild ...
--
-- If these tools not exist, we will install it first.
--
function enter()

    -- set search pathes of toolchains 
    environment.enter("toolchains")

    -- git not found? install it first
    if not find_tool("git") then
        package.install_packages("git")
    end

    -- get prefix directories
    local plat = get_config("plat")
    local arch = get_config("arch")
    _g.prefixdirs = _g.prefixdirs or 
    {
        core_package.prefixdir(false, false, plat, arch),
        core_package.prefixdir(false, true, plat, arch),
        core_package.prefixdir(true, false, plat, arch), 
        core_package.prefixdir(true, true, plat, arch)
    }

    -- add search directories of pkgconfig, aclocal, cmake 
    _g._ACLOCAL_PATH = os.getenv("ACLOCAL_PATH")
    _g._PKG_CONFIG_PATH = os.getenv("PKG_CONFIG_PATH")
    _g._CMAKE_PREFIX_PATH = os.getenv("CMAKE_PREFIX_PATH")
    for _, prefixdir in ipairs(_g.prefixdirs) do
        if not is_plat("windows") then
            os.addenv("ACLOCAL_PATH", path.join(prefixdir, "share", "aclocal"))
            os.addenv("PKG_CONFIG_PATH", path.join(prefixdir, "lib", "pkgconfig"))
        end
        os.addenv("CMAKE_PREFIX_PATH", prefixdir)
    end
end

-- leave environment
function leave()

    -- restore search directories of pkgconfig, aclocal, cmake 
    os.setenv("ACLOCAL_PATH", _g._ACLOCAL_PATH)
    os.setenv("PKG_CONFIG_PATH", _g._PKG_CONFIG_PATH)
    os.setenv("CMAKE_PREFIX_PATH", _g._CMAKE_PREFIX_PATH)

    -- restore search pathes of toolchains
    environment.leave("toolchains")
end
