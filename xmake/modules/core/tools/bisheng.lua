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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      wuzhenqing
-- @file        bisheng.lua
--

inherit("clang")

function init(self)
    _super.init(self)
    self:add("shared.ascflags", "-fPIC")
    self:add("shared.aicpuflags", "-fPIC")
    self:add("ascflags", "-Qunused-arguments")
    self:add("aicpuflags", "-Qunused-arguments")
    self:set("ascshflags", "-shared")
end

-- make the language flag
function nf_language(self, stdname)
    if _g.cxxmaps == nil then
        _g.cxxmaps =
        {
            cxx03       = "-std=c++03"
        ,   cxx11       = "-std=c++11"
        ,   cxx14       = "-std=c++14"
        ,   cxx17       = "-std=c++17"
        ,   cxx20       = "-std=c++20"
        ,   cxxlatest   = {"-std=c++20", "-std=c++17", "-std=c++14", "-std=c++11", "-std=c++03"}
        }
        local cxxmaps2 = {}
        for k, v in pairs(_g.cxxmaps) do
            cxxmaps2[k:gsub("xx", "++")] = v
        end
        table.join2(_g.cxxmaps, cxxmaps2)
    end
    local result = _g.cxxmaps[stdname]
    if type(result) == "table" then
        local flagkind = self:kind() == "aicpu" and "aicpuflags" or "ascflags"
        for _, flag in ipairs(result) do
            if self:has_flags(flag, flagkind) then
                result = flag
                _g.cxxmaps[stdname] = result
                break
            end
        end
    end
    return result
end

-- add source kind override flags (e.g. for .cce files compiled as asc)
function add_sourceflags(self, sourcefile, fileconfig, target, targetkind)
    local sourcekind = fileconfig.sourcekind
    if sourcekind then
        local maps = {asc = "-x asc", aicpu = "-x aicpu"}
        return maps[sourcekind]
    end
end
