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
-- @file        swiftc.lua
--

-- imports
import("core.project.config")
import("detect.tools.find_ccache")

-- init it
function init(program, kind)
    
    -- save the shell name
    _g.program = program or "swiftc"

    -- init kind
    _g.kind = kind

    -- init flags map
    _g.mapflags = 
    {
        -- symbols
        ["-fvisibility=hidden"]     = ""

        -- warnings
    ,   ["-w"]                      = ""
    ,   ["-W.*"]                    = ""

        -- optimize
    ,   ["-O0"]                     = "-Onone"
    ,   ["-Ofast"]                  = "-Ounchecked"
    ,   ["-O.*"]                    = "-O"

        -- vectorexts
    ,   ["-m.*"]                    = ""

        -- strip
    ,   ["-s"]                      = ""
    ,   ["-S"]                      = ""

        -- others
    ,   ["-ftrapv"]                 = ""
    ,   ["-fsanitize=address"]      = ""
    }

    -- init features
    _g.features = 
    {
        ["object:sources"]      = false
    }
end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the strip flag
function nf_strip(level)

    -- the maps
    local maps = 
    {   
        debug       = "-Xlinker -S"
    ,   all         = "-Xlinker -s"
    }

    -- make it
    return maps[level] or ""
end

-- make the symbol flag
function nf_symbol(level)

    -- the maps
    local maps = 
    {   
        debug = "-g"
    }

    -- make it
    return maps[level] or ""
end

-- make the warning flag
function nf_warning(level)

    -- the maps
    local maps = 
    {   
        none        = "-w"
    ,   less        = "-W1"
    ,   more        = "-W3"
    ,   all         = "-Wall"
    ,   error       = "-Werror"
    }

    -- make it
    return maps[level] or ""
end

-- make the optimize flag
function nf_optimize(level)

    -- the maps
    local maps = 
    {   
        none        = "-Onone"
    ,   fast        = "-O"
    ,   faster      = "-O"
    ,   fastest     = "-O"
    ,   smallest    = "-O"
    ,   aggressive  = "-Ounchecked"
    }

    -- make it
    return maps[level] or ""
end

-- make the vector extension flag
function nf_vectorext(extension)

    -- the maps
    local maps = 
    {   
        mmx         = "-mmmx"
    ,   sse         = "-msse"
    ,   sse2        = "-msse2"
    ,   sse3        = "-msse3"
    ,   ssse3       = "-mssse3"
    ,   avx         = "-mavx"
    ,   avx2        = "-mavx2"
    ,   neon        = "-mfpu=neon"
    }

    -- make it
    return maps[extension] or ""
end

-- make the includedir flag
function nf_includedir(dir)

    -- make it
    return "-Xcc -I" .. dir
end

-- make the define flag
function nf_define(macro)

    -- make it
    return "-Xcc -D" .. macro:gsub("\"", "\\\"")
end

-- make the undefine flag
function nf_undefine(macro)

    -- make it
    return "-Xcc -U" .. macro
end

-- make the framework flag
function nf_framework(framework)

    -- make it
    return "-framework" .. framework
end

-- make the link flag
function nf_link(lib)

    -- make it
    return "-l" .. lib
end

-- make the linkdir flag
function nf_linkdir(dir)

    -- make it
    return "-L" .. dir
end

-- make the link command
function linkcmd(objectfiles, targetkind, targetfile, flags)

    -- make it
    return format("%s -o %s %s %s", _g.program, targetfile, objectfiles, flags)
end

-- link the target file
function link(objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.run(linkcmd(objectfiles, targetkind, targetfile, flags))
end

-- make the compile command
function _compcmd1(sourcefile, objectfile, flags)

    -- get ccache
    local ccache = nil
    if config.get("ccache") then
        ccache = find_ccache()
    end

    -- make it
    local command = format("%s -c %s -o %s %s", _g.program, flags, objectfile, sourcefile)
    if ccache then
        command = ccache:append(command, " ")
    end

    -- ok
    return command
end

-- complie the source file
function _compile1(sourcefile, objectfile, incdepfile, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.run(_compcmd1(sourcefile, objectfile, flags))
end

-- make the complie command
function compcmd(sourcefiles, objectfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    return _compcmd1(sourcefiles, objectfile, flags)
end

-- complie the source file
function compile(sourcefiles, objectfile, incdepfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    _compile1(sourcefiles, objectfile, incdepfile, flags)
end

-- check the given flags 
function check(flags)

    -- check it
    os.run("%s -h", _g.program)
end
