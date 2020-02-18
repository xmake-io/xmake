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
-- @file        cmake.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_file")

-- detect build-system and configuration file
function detect()
    return find_file("CMakeLists.txt", os.curdir())
end

-- do build
function build()
    os.mkdir("build")
    os.cd("build")
    if is_host("windows") and os.arch() == "x64" then
        os.exec("cmake -A x64 -DCMAKE_INSTALL_PREFIX=\"%s\" ..", path.absolute("build/install"))
    else
        os.exec("cmake -DCMAKE_INSTALL_PREFIX=\"%s\" ..", path.absolute("build/install"))
    end
    if is_host("windows") then
        
        local slnfile = assert(find_file("*.sln", os.curdir()), "*.sln file not found!")
        os.exec("msbuild \"%s\" -nologo -t:Rebuild -p:Configuration=Release -p:Platform=%s", slnfile, os.arch() == "x64" and "x64" or "Win32")

        local projfile = os.isfile("INSTALL.vcxproj") and "INSTALL.vcxproj" or "INSTALL.vcproj"
        os.exec("msbuild \"%s\" /property:configuration=Release", projfile)
    else
        os.exec("make -j4")
        os.exec("make install")
    end
    cprint("installed to ${bright}%s", path.absolute("build/install"))
    cprint("${bright}build ok!")
end


