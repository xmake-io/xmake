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
-- @file        clang.lua
--

-- inherit gcc
inherit("gcc")

-- init it
function init(self)

    -- init super
    _super.init(self)

    -- add cuflags
    if not is_plat("windows", "mingw") then
        self:add("shared.cuflags", "-fPIC")
    end

    -- suppress warning 
    self:add("cxflags", "-Qunused-arguments")
    self:add("cuflags", "-Qunused-arguments")
    self:add("mxflags", "-Qunused-arguments")
    self:add("asflags", "-Qunused-arguments")

    -- add cuda path 
    local cuda = get_config("cuda")
    if cuda then
        local cuda_path = "--cuda-path=" .. os.args(path.translate(cuda))
        self:add("cuflags", cuda_path)
    end

    -- init flags map
    self:set("mapflags",
    {
        -- warnings
        ["-W1"] = "-Wall"
    ,   ["-W2"] = "-Wall"
    ,   ["-W3"] = "-Wall"
    ,   ["-W4"] = "-Wextra"

         -- strip
    ,   ["-s"]  = "-s"
    ,   ["-S"]  = "-S"

        -- rdc
    ,   ["-rdc=true"] = "-fcuda-rdc"
    ,   ["-rdc true"] = "-fcuda-rdc"
    ,   ["--relocatable-device-code=true"] = "-fcuda-rdc"
    ,   ["--relocatable-device-code true"] = "-fcuda-rdc"
    ,   ["-rdc=false"] = ""
    ,   ["-rdc false"] = ""
    ,   ["--relocatable-device-code=false"] = ""
    ,   ["--relocatable-device-code false"] = ""
    })

end

-- make the optimize flag
function nf_optimize(self, level)

    -- the maps
    local maps = 
    {   
        none       = "-O0"
    ,   fast       = "-O1"
    ,   faster     = "-O2"
    ,   fastest    = "-O3"
    ,   smallest   = "-Oz" -- smaller than -Os
    ,   aggressive = "-Ofast"
    }

    -- make it
    return maps[level] 
end

-- make the warning flag
function nf_warning(self, level)

    -- the maps
    local maps = 
    {   
        none       = "-w"
    ,   less       = "-Wall"
    ,   more       = "-Wall"
    ,   all        = "-Wall"
    ,   everything = "-Weverything"
    ,   error      = "-Werror"
    }

    -- make it
    return maps[level]
end
