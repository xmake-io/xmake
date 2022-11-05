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
-- @file        clang.lua
--

-- inherit gcc
inherit("gcc")
import("core.language.language")

-- init it
function init(self)

    -- init super
    _super.init(self)

    -- add cuflags
    if not self:is_plat("windows", "mingw") then
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
    ,   ["-W4"] = "-Wall -Wextra"

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

-- make the fp-model flag
function nf_fpmodel(self, level)
    local maps
    if self:has_flags("-ffp-model=fast") then
        maps =
        {
            precise    = "-ffp-model=precise"
        ,   fast       = "-ffp-model=fast"
        ,   strict     = "-ffp-model=strict"
        ,   except     = "-ftrapping-math"
        ,   noexcept   = "-fno-trapping-math"
        }
    else
        maps =
        {
            precise    = "" -- default
        ,   fast       = "-ffast-math"
        ,   strict     = {"-frounding-math", "-ftrapping-math"}
        ,   except     = "-ftrapping-math"
        ,   noexcept   = "-fno-trapping-math"
        }
    end
    return maps[level]
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps =
        {
            none       = "-O0"
        ,   fast       = "-O1"
        ,   faster     = "-O2"
        ,   fastest    = "-O3"
        ,   smallest   = "-Oz" -- smaller than -Os
        ,   aggressive = "-Ofast"
        }
        return maps[level]
    end
end

-- make the warning flag
function nf_warning(self, level)
    local maps =
    {
        none       = "-w"
    ,   less       = "-Wall"
    ,   more       = "-Wall"
    ,   all        = "-Wall"
    ,   allextra   = "-Wall -Wextra"
    ,   everything = "-Weverything"
    ,   error      = "-Werror"
    }
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)
    local kind = self:kind()
    if kind == "ld" or kind == "sh" then
        -- clang/windows need add `-g` to linker to generate pdb symbol file
        if self:is_plat("windows") and level == "debug" then
            return "-g"
        end
    else
        return _super.nf_symbol(self, level)
    end
end

-- make the exception flag
--
-- e.g.
-- set_exceptions("cxx")
-- set_exceptions("objc")
-- set_exceptions("no-cxx")
-- set_exceptions("no-objc")
-- set_exceptions("cxx", "objc")
function nf_exception(self, exp)
    local maps = {
        cxx = "-fcxx-exceptions",
        ["no-cxx"] = "-fno-cxx-exceptions",
        objc = "-fobjc-exceptions",
        ["no-objc"] = "-fno-objc-exceptions"
    }
    local value = maps[exp]
    if value then
        return {exp:startswith("no-") and "-fno-exceptions" or "-fexceptions", value}
    end
end

