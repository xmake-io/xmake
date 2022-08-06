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
-- @file        emcc.lua
--

-- inherit gcc
inherit("gcc")

-- make the optimize flag
--
-- same options must be used at compile and link, @see https://github.com/xmake-io/xmake/issues/2455
-- https://emscripten.org/docs/compiling/Building-Projects.html?highlight=optimization#building-projects-optimizations
function nf_optimize(self, level)
    local maps = {
        none       = "-O0"
    ,   fast       = "-O1"
    ,   faster     = "-O2"
    ,   fastest    = "-O3"
    ,   smallest   = "-Os"
    ,   aggressive = "-O3"
    }
    return maps[level]
end

-- make the strip flag
function nf_strip(self, level)
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
end

-- make the symbol flag
function nf_symbol(self, level)
    local kind = self:kind()
    if kind == "ld" or kind == "sh" then
        -- emscripten requires -g when linking to map JS/wasm code back to original source
        if level == "debug" then
            return "-g"
        end
    end

    return _super.nf_symbol(self, level)
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags, opt)

    -- init arguments
    opt = opt or {}
    local argv = table.join("-o", targetfile, objectfiles, flags)
    if is_host("windows") and not opt.rawargs then
        argv = winos.cmdargv(argv, {escape = true})
    end
    return self:program(), argv
end
