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

-- build package
function build(package)
    os.mkdir("build/install")
    os.cd("build")
    os.vrun("cmake -a $(arch) -DCMAKE_INSTALL_PREFIX=\"%s\" ..", path.absolute("install"))
    if is_host("windows") then
        local slnfile = assert(find_file("*.sln", os.curdir()), "*.sln file not found!")
        os.vrun("msbuild \"%s\" -nologo -t:Rebuild -p:Configuration=%s -p:Platform=%s", slnfile, is_mode("debug") and "Debug" or "Release", is_arch("x64") and "x64" or "Win32")
    else
        os.vrun("make")
    end
end

-- install package
function install(package)
    os.cd("build")
    if is_host("windows") then
        local projfile = os.isfile("INSTALL.vcxproj") and "INSTALL.vcxproj" or "INSTALL.vcproj"
        os.vrun("msbuild \"%s\" /property:configuration=%s", projfile, is_mode("debug") and "Debug" or "Release")
    else
        os.vrun("make install")
    end
    os.cp("install/lib", package:installdir())
    os.cp("install/include", package:installdir())
end

