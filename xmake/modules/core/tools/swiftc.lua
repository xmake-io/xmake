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
function init(self)
    
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
function get(self, name)
    return _g[name]
end

-- make the strip flag
function nf_strip(self, level)

    -- the maps
    local maps = 
    {   
        debug = {"-Xlinker", "-S"}
    ,   all   = {"-Xlinker", "-s"}
    }

    -- make it
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)

    -- the maps
    local maps = 
    {   
        debug = "-g"
    }

    -- make it
    return maps[level]
end

-- make the warning flag
function nf_warning(self, level)

    -- the maps
    local maps = 
    {   
        none  = "-w"
    ,   less  = "-W1"
    ,   more  = "-W3"
    ,   all   = "-Wall"
    ,   error = "-Werror"
    }

    -- make it
    return maps[level] 
end

-- make the optimize flag
function nf_optimize(self, level)

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
    return maps[level]
end

-- make the vector extension flag
function nf_vectorext(self, extension)

    -- the maps
    local maps = 
    {   
        mmx   = "-mmmx"
    ,   sse   = "-msse"
    ,   sse2  = "-msse2"
    ,   sse3  = "-msse3"
    ,   ssse3 = "-mssse3"
    ,   avx   = "-mavx"
    ,   avx2  = "-mavx2"
    ,   neon  = "-mfpu=neon"
    }

    -- make it
    return maps[extension] or ""
end

-- make the includedir flag
function nf_includedir(self, dir)
    return {"-Xcc", "-I" .. dir}
end

-- make the define flag
function nf_define(self, macro)
    return {"-Xcc", "-D" .. macro}
end

-- make the undefine flag
function nf_undefine(self, macro)
    return {"-Xcc", "-U" .. macro}
end

-- make the framework flag
function nf_framework(self, framework)
    return {"-framework", framework}
end

-- make the link flag
function nf_link(self, lib)
    return "-l" .. lib
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return "-L" .. dir
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)
    return self:program(), table.join("-o", targetfile, objectfiles, flags)
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- make the compile arguments list
function _compargv1(self, sourcefile, objectfile, flags)

    -- get ccache
    local ccache = nil
    if config.get("ccache") then
        ccache = find_ccache()
    end

    -- make argv
    local argv = table.join("-c", flags, "-o", objectfile, sourcefile)

    -- uses cache?
    local program = self:program()
    if ccache then
            
        -- parse the filename and arguments, .e.g "xcrun -sdk macosx clang"
        if not os.isexec(program) then
            argv = table.join(program:split("%s"), argv)
        else 
            table.insert(argv, 1, program)
        end
        return ccache, argv
    end

    -- no cache
    return program, argv
end

-- complie the source file
function _compile1(self, sourcefile, objectfile, incdepfile, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.runv(_compargv1(self, sourcefile, objectfile, flags))
end

-- make the complie arguments list
function compargv(self, sourcefiles, objectfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    return _compargv1(self, sourcefiles, objectfile, flags)
end

-- complie the source file
function compile(self, sourcefiles, objectfile, incdepfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    _compile1(self, sourcefiles, objectfile, incdepfile, flags)
end

