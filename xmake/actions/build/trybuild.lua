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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        trybuild.lua
--

-- imports
import("core.base.option")
import("core.platform.environment")
import("lib.detect.find_file")

-- try building for makefile
function _build_for_makefile(buildfile)
    os.vrun("make -j4")
end

-- try building for configure
function _build_for_configure(buildfile)
    if not os.isfile("configure") then
        if os.isfile("autogen.sh") then
            os.vrunv("sh", {"./autogen.sh"})
        elseif os.isfile("configure.ac") then
            os.vrun("autoreconf --install --symlink")
        end
    end
    os.vrun("./configure --prefix=%s", path.absolute("install"))
    os.vrun("make -j4")
    os.vrun("make install")
end

-- try building for cmakelist
function _build_for_cmakelists(buildfile)
    os.mkdir("build")
    os.cd("build")
    if is_host("windows") and os.arch() == "x64" then
        os.vrun("cmake -A x64 -DCMAKE_INSTALL_PREFIX=\"%s\" ..", path.absolute("install"))
    else
        os.vrun("cmake -DCMAKE_INSTALL_PREFIX=\"%s\" ..", path.absolute("install"))
    end
    if is_host("windows") then
        
        local slnfile = assert(find_file("*.sln", os.curdir()), "*.sln file not found!")
        os.vrun("msbuild \"%s\" -nologo -t:Rebuild -p:Configuration=Release -p:Platform=%s", slnfile, os.arch() == "x64" and "x64" or "Win32")

        local projfile = os.isfile("INSTALL.vcxproj") and "INSTALL.vcxproj" or "INSTALL.vcproj"
        os.vrun("msbuild \"%s\" /property:configuration=Release", projfile)
    else
        os.vrun("make -j4")
        os.vrun("make install")
    end
end

-- build for *.sln
function _build_for_sln(buildfile)
    os.vrun("msbuild \"%s\" -nologo -t:Rebuild -p:Configuration=Release -p:Platform=%s", buildfile, os.arch() == "x64" and "x64" or "Win32")
end

-- build for *.xcworkspace or *.xcodeproj
function _build_for_xcode(buildfile)
    os.vrun("xcodebuild clean build CODE_SIGN_IDENTITY=\"\" CODE_SIGNING_REQUIRED=NO")
end

-- the main entry
function main(targetname)

    -- trace
    cprint("${color.warning}xmake.lua not found, try building ..")

    -- enter toolchains environment
    environment.enter("toolchains")

    -- TODO *.vcproj, premake.lua, scons, autogen.sh, Makefile.am, ...
    -- init build scripts
    local buildscripts = {}
    if is_host("windows") then
        table.insert(buildscripts, {"*.sln",          _build_for_sln})
    elseif is_host("macosx") then
        table.insert(buildscripts, {"*.xcworkspace",  _build_for_xcode})
        table.insert(buildscripts, {"*.xcodeproj",    _build_for_xcode})
    end
    table.insert(buildscripts, {"CMakeLists.txt", _build_for_cmakelists})
    table.insert(buildscripts, {"configure",      _build_for_configure})
    table.insert(buildscripts, {"configure.ac",   _build_for_configure})
    table.insert(buildscripts, {"[mM]akefile",    _build_for_makefile})

    -- attempt to build it
    local ok = false
    for _, buildscript in pairs(buildscripts) do

        -- save the current directory 
        local oldir = os.curdir()

        -- try building 
        ok = try
        {
            function ()

                -- attempt to build it if file exists
                local files = os.filedirs(buildscript[1])
                if #files > 0 then

                    -- trace
                    print("%s found", path.filename(files[1]))

                    -- build it
                    buildscript[2](files[1])
                    return true
                end
            end,

            catch
            {
                function (errors)

                    -- trace verbose info
                    if errors then
                        vprint(errors)
                    end
                end
            }
        }

        -- restore directory
        os.cd(oldir)

        -- ok?
        if ok then break end
    end

    -- leave toolchains environment
    environment.leave("toolchains")

    -- trace
    if ok then
        cprint("${bright}build ok!${clear}")
    else
        raise("build failed!")
    end
end


