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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        memory.lua
--

-- define module
local memory = memory or {}

-- load modules
local os = require("base/os")

-- get memory info
function memory.info(name)
    local meminfo = memory._MEMINFO
    local memtime = memory._MEMTIME
    if meminfo == nil or memtime == nil or os.time() - memtime > 10 then -- cache 10s
        meminfo = os._meminfo()
        if meminfo.totalsize and meminfo.availsize then
            meminfo.usagerate = (meminfo.totalsize - meminfo.availsize) / meminfo.totalsize
        else
            meminfo.usagerate = 0
        end
        memory._MEMINFO = meminfo
        memory._MEMTIME = os.time()
    end
    if name then
        return meminfo[name]
    else
        return meminfo
    end
end

-- return module
return memory
