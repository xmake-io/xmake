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
-- @file        autotools.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("lib.detect.find_file")

-- get build directory
function _get_buildir()
    return config.buildir()
end

-- get artifacts directory
function _get_artifacts_dir()
    return path.absolute(path.join(_get_buildir(), "artifacts"))
end

-- detect build-system and configuration file
function detect()
    return find_file("configure", os.curdir()) or find_file("configure.ac", os.curdir())
end

-- do clean
function clean()
    if find_file("[mM]akefile", os.curdir()) then
        os.exec("make clean")
        if option.get("all") then
            os.tryrm(_get_artifacts_dir())
        end
    end
end

-- do build
function build()

    -- get artifacts directory
    local artifacts_dir = _get_artifacts_dir()
    if not os.isdir(artifacts_dir) then
        os.mkdir(artifacts_dir)
    end

    -- generate configure 
    if not os.isfile("configure") then
        if os.isfile("autogen.sh") then
            os.execv("sh", {"./autogen.sh"})
        elseif os.isfile("configure.ac") then
            os.exec("autoreconf --install --symlink")
        end
    end

    -- do configure
    if not find_file("[mM]akefile", os.curdir()) then
        os.execv("./configure", "--prefix=" .. artifacts_dir)
    end

    -- do build
    os.exec("make -j" .. option.get("jobs"))
    os.exec("make install")
    cprint("output to ${bright}%s", artifacts_dir)
    cprint("${bright}build ok!")
end


