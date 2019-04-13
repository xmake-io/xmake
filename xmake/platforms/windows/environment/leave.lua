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
-- @file        leave.lua
--

-- leave the given environment
function _leave(platform, name)
    local old = platform:data("windows.environment." .. name)
    if old then 
        os.setenv(name, old)
    end
end

-- leave the toolchains environment
function _leave_toolchains(platform)
    _leave(platform, "path")
    _leave(platform, "lib")
    _leave(platform, "include")
    _leave(platform, "libpath")
end

-- leave environment
function main(platform, name)
    local maps = {toolchains = _leave_toolchains}
    local func = maps[name]
    if func then
        func(platform)
    end
end
