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
-- @file        cosmocc.lua
--

-- inherit gcc
inherit("gcc")

-- init it
function init(self)
    _super.init(self)
end

-- make the strip flag
function nf_strip(self, level)
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags, opt)
    opt = opt or {}
    if is_host("windows") then
        targetfile = targetfile:gsub("\\", "/")
        local objectfiles_new = {}
        for idx, objectfile in ipairs(objectfiles) do
            objectfiles_new[idx] = objectfiles[idx]:gsub("\\", "/")
        end
        objectfiles = objectfiles_new
    end
    return _super.link(self, objectfiles, targetkind, targetfile, flags, table.join(opt, {shell = true}))
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags, opt)
    opt = opt or {}
    if is_host("windows") then
        sourcefile = sourcefile:gsub("\\", "/")
        objectfile = objectfile:gsub("\\", "/")
        local target = opt.target
        if target then
            target:set("policy", "build.ccache", false)
        end
    end
    return _super.compile(self, sourcefile, objectfile, dependinfo, flags, table.join(opt, {shell = true}))
end
