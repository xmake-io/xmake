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
-- @file        global.lua
--

-- imports
import("core.base.global")
import("private.platform.check_arch")
import("private.platform.check_vstudio")

-- clean temporary global configs
function _clean_global()
    global.set("arch", nil)
    global.set("__vcvarsall", nil)
end

-- check it
function main(platform, name)

    -- we cannot check the global configuration with the given name
    if name then
        raise("we cannot check global." .. name)
    end

    -- check arch 
    check_arch(global)

    -- check vstudio
    check_vstudio(global)

    -- clean temporary global configs
    _clean_global()
end

