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
-- @file        nim.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")

-- init it
function init(self)

    -- init arflags
    self:set("ncarflags", "--app:staticlib")

    -- init shflags
    self:set("ncshflags", "--app:lib")
end

-- make the define flag
function nf_define(self, macro)
    return "--define:" .. macro
end

-- make the undefine flag
function nf_undefine(self, macro)
    return "--undef:" .. macro
end

-- make the optimize flag
function nf_optimize(self, level)
    local maps =
    {
        none        = "--opt:none"
    ,   fast        = "--opt:speed"
    ,   faster      = "--opt:speed"
    ,   fastest     = "--opt:speed"
    ,   smallest    = "--opt:size"
    ,   aggressive  = "--opt:speed"
    }
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)
    local maps =
    {
        debug = "--stackTrace:on"
    }
    return maps[level]
end

-- make the link flag
function nf_link(self, lib)
    return "--passL:" .. lib
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return {"-L" .. dir}
end

-- make the build arguments list
function buildargv(self, sourcefiles, targetkind, targetfile, flags)
    return self:program(), table.join(flags, "c", "-o:" .. targetfile, sourcefiles)
end

-- build the target file
function build(self, sourcefiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    os.runv(buildargv(self, sourcefiles, targetkind, targetfile, flags))
end

