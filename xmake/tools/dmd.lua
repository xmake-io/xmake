--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        dmd.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")

-- init it
function init(program, kind)
    
    -- save the shell name
    _g.program = program or "dmd"

    -- save the kind
    _g.kind = kind

    -- init arflags
    _g.arflags = { "-lib" }

    -- init shflags
    _g.shflags = { "-shared", "-fPIC" }

    -- init dcflags for the kind: shared
    _g.shared           = {}
    _g.shared.dcflags   = {"-fPIC"}

    -- init features
    _g.features = 
    {
        ["object:sources"] = false
    }
end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the optimize flag
function nf_optimize(level)

    -- the maps
    local maps = 
    {   
        none        = ""
    ,   fast        = "-O"
    ,   faster      = "-O -release"
    ,   fastest     = "-O -release -inline -boundscheck=off"
    ,   smallest    = "-O -release -boundscheck=off"
    ,   aggressive  = "-O -release -inline -boundscheck=off"
    }

    -- make it
    return maps[level] or ""
end

-- make the strip flag
function nf_strip(level)

    -- the maps
    local maps = 
    {   
        debug       = "-L-S"
    ,   all         = "-L-s"
    }

    -- make it
    return maps[level] or ""
end

-- make the symbol flag
function nf_symbol(level)

    -- the maps
    local maps = 
    {   
        debug       = "-g -debug"
    ,   hidden      = ""
    }

    -- make it
    return maps[level] or ""
end

-- make the warning flag
function nf_warning(level)

    -- the maps
    local maps = 
    {   
        none        = "-d"
    ,   less        = "-w"
    ,   more        = "-w -wi"
    ,   all         = "-w -wi"
    ,   error       = "-de"
    }

    -- make it
    return maps[level] or ""
end

-- make the vector extension flag
function nf_vectorext(extension)

    -- the maps
    local maps = 
    {   
        avx         = "-mcpu=avx"
    ,   avx2        = "-mcpu=avx"
    }

    -- make it
    return maps[extension] or ""
end

-- make the includedir flag
function nf_includedir(dir)

    -- make it
    return "-I" .. dir
end

-- make the link flag
function nf_link(lib)

    -- make it
    return "-L-l" .. lib
end

-- make the linkdir flag
function nf_linkdir(dir)

    -- make it
    return "-L-L" .. dir
end

-- make the rpathdir flag
function nf_rpathdir(dir)

    -- check this flag
    local flag = "-L-rpath=" .. dir
    if _g._RPATH == nil then
        _g._RPATH = try
        {
            function ()
                check(flag, true)
                return true
            end
        }
    end

    -- ok?
    if _g._RPATH then
        return flag
    end
end

-- make the link command
function linkcmd(objectfiles, targetkind, targetfile, flags)

    -- make it
    return format("%s %s -of%s %s", _g.program, flags, targetfile, objectfiles)
end

-- link the target file
function link(objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.run(linkcmd(objectfiles, targetkind, targetfile, flags))
end

-- make the complie command
function compcmd(sourcefiles, objectfile, flags)

    -- make it
    return format("%s -c %s -of%s %s", _g.program, flags, objectfile, table.concat(table.wrap(sourcefiles), " "))
end

-- complie the source file
function compile(sourcefiles, objectfile, incdepfile, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.run(compcmd(sourcefiles, objectfile, flags))
end

-- check the given flags 
function check(flags, trylink)

    -- make an stub source file
    local binaryfile = os.tmpfile() .. ".b"
    local objectfile = os.tmpfile() .. ".o"
    local sourcefile = os.tmpfile() .. ".d"

    -- make stub code
    io.writefile(sourcefile, "void main() {\n}")

    -- check it, need check compflags and linkflags
    if trylink then
        os.run("%s %s -of%s %s", _g.program, ifelse(flags, flags, ""), binaryfile, sourcefile)
    else
        os.run("%s -c %s -of%s %s", _g.program, ifelse(flags, flags, ""), binaryfile, sourcefile)
    end

    -- remove files
    os.tryrm(binaryfile)
    os.tryrm(objectfile)
    os.tryrm(sourcefile)
end
