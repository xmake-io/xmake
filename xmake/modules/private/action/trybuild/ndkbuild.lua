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
-- @file        ndkbuild.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("lib.detect.find_file")

-- get ndk directory
function _get_ndkdir()
    local ndk = assert(config.get("ndk"), "ndkbuild: please uses `xmake f --ndk=` to set the ndk path!")
    return path.absolute(ndk)
end

-- detect build-system and configuration file
function detect()
    return find_file("Android.mk", path.join(os.curdir(), "jni"))
end

-- do clean
function clean()

    -- get the ndk root directory
    local ndk = _get_ndkdir()
    assert(os.isdir(ndk), "%s not found!", ndk)

    -- do clean
    os.vexecv(path.join(ndk, "ndk-build"), {"clean"}, {envs = {NDK_ROOT = ndk}})
end

-- do build
function build()

    -- only support the android platform now!
    assert(is_plat("android"), "ndkbuild: please uses `xmake f -p android --trybuild=ndkbuild` to switch to android platform!")

    -- get the ndk root directory
    local ndk = _get_ndkdir()
    assert(os.isdir(ndk), "%s not found!", ndk)

    -- do build
    local argv = {}
    if option.get("verbose") then
        table.insert(argv, "V=1")
    end
    local ndkbuild = path.join(ndk, "ndk-build")
    if is_host("windows") then
        ndkbuild = ndkbuild .. ".cmd"
    end
    os.vexecv(ndkbuild, argv, {envs = {NDK_ROOT = ndk}})
    cprint("${color.success}build ok!")
end
