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
-- @file        cmake.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_file")

-- install package
function install(package, configs)
    os.mkdir("build/install")
    local oldir = os.cd("build")
    if is_plat("windows") and is_arch("x64") then
        os.vrun("cmake -A x64 -DCMAKE_INSTALL_PREFIX=\"%s\" ..", path.absolute("install"))
    else
        os.vrun("cmake -DCMAKE_INSTALL_PREFIX=\"%s\" ..", path.absolute("install"))
    end
    if is_host("windows") then
        local slnfile = assert(find_file("*.sln", os.curdir()), "*.sln file not found!")
        os.vrun("msbuild \"%s\" -nologo -t:Rebuild -p:Configuration=%s -p:Platform=%s", slnfile, package:debug() and "Debug" or "Release", is_arch("x64") and "x64" or "Win32")
        local projfile = os.isfile("INSTALL.vcxproj") and "INSTALL.vcxproj" or "INSTALL.vcproj"
        if os.isfile(projfile) then
            os.vrun("msbuild \"%s\" /property:configuration=%s", projfile, package:debug() and "Debug" or "Release")
            os.cp("install/lib", package:installdir())
            os.cp("install/include", package:installdir())
        else
            os.cp("**.lib", package:installdir("lib"))
            os.cp("**.dll", package:installdir("lib"))
            os.cp("**.exp", package:installdir("lib"))
        end
    else
        os.vrun("make -j4")
        os.vrun("make install")
        os.cp("install/lib", package:installdir())
        os.cp("install/include", package:installdir())
    end
    os.cd(oldir)
end

