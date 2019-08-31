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
-- @file        dmd.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")

-- init it
function init(self)
    
    -- init arflags
    self:set("dc-arflags", "-lib")

    -- init shflags
    self:set("dc-shflags", "-shared", "-fPIC")

    -- init dcflags for the kind: shared
    self:set("shared.dcflags", "-fPIC")
end

-- make the optimize flag
function nf_optimize(self, level)

    -- the maps
    local maps = 
    {   
        fast        = "-O"
    ,   faster      = "-O -release"
    ,   fastest     = "-O -release -inline -boundscheck=off"
    ,   smallest    = "-O -release -boundscheck=off"
    ,   aggressive  = "-O -release -inline -boundscheck=off"
    }

    -- make it
    return maps[level] 
end

-- make the strip flag
function nf_strip(self, level)

    -- the maps
    local maps = 
    {   
        debug       = "-L-S"
    ,   all         = "-L-s"
    }

    -- make it
    return maps[level] 
end

-- make the symbol flag
function nf_symbol(self, level)

    -- the maps
    local maps = 
    {   
        debug = "-g -debug"
    }

    -- make it
    return maps[level] 
end

-- make the warning flag
function nf_warning(self, level)

    -- the maps
    local maps = 
    {   
        none        = "-d"
    ,   less        = "-w"
    ,   more        = "-w -wi"
    ,   all         = "-w -wi"
    ,   everything  = "-w -wi"
    ,   error       = "-de"
    }

    -- make it
    return maps[level]
end

-- make the vector extension flag
function nf_vectorext(self, extension)

    -- the maps
    local maps = 
    {   
        avx         = "-mcpu=avx"
    ,   avx2        = "-mcpu=avx"
    }

    -- make it
    return maps[extension] 
end

-- make the includedir flag
function nf_includedir(self, dir)
    return "-I" .. os.args(dir)
end

-- make the link flag
function nf_link(self, lib)
    return "-L-l" .. lib
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return "-L-L" .. os.args(dir)
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    local flag = "-L-rpath=" .. os.args(dir)
    if self:has_flags(flag) then
        return flag
    end
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)
    return self:program(), table.join(flags, "-of" .. targetfile, objectfiles)
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- make the compile arguments list
function compargv(self, sourcefiles, objectfile, flags)
    return self:program(), table.join("-c", flags, "-of" .. objectfile, sourcefiles)
end

-- compile the source file
function compile(self, sourcefiles, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.runv(compargv(self, sourcefiles, objectfile, flags))
end

