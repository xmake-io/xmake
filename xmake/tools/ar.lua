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
-- @file        ar.lua
--

-- imports
import("core.tool.compiler")

-- init it
function init(program, kind)
    
    -- save the shell name
    _g.program = program or "ar"

    -- save the tool kind
    _g.kind = kind or "ar"

    -- init arflags
    _g.arflags = { "-cr" }

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the strip flag
function strip(level)

    -- the maps
    local maps = 
    {   
        debug       = "-S"
    ,   all         = "-s"
    }

    -- make it
    return maps[level] or ""
end

-- make the link command
function linkcmd(objectfiles, targetkind, targetfile, flags)

    -- check
    assert(targetkind == "static")

    -- make it
    return format("%s %s %s %s", _g.program, flags, targetfile, objectfiles)
end

-- link the library file
function link(objectfiles, targetkind, targetfile, flags)

    -- check
    assert(targetkind == "static", "the target kind: %s is not support for ar", targetkind)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.run(linkcmd(objectfiles, targetkind, targetfile, flags))
end

-- extract the static library to object directory
function extract(libraryfile, objectdir)

    -- make the object directory first
    os.mkdir(objectdir)

    -- get the absolute path of this library
    libraryfile = path.absolute(libraryfile)

    -- enter the object directory
    local olddir = os.cd(objectdir)

    -- extract it
    os.run("%s -x %s", _g.program, libraryfile)

    -- check repeat object name
    local repeats = {}
    local objectfiles = os.iorun("%s -t %s", _g.program, libraryfile)
    for _, objectfile in ipairs(objectfiles:split('\n')) do
        if repeats[objectfile] then
            raise("object name(%s) conflicts in library: %s", objectfile, libraryfile)
        end
        repeats[objectfile] = true
    end                                                          

    -- leave the object directory
    os.cd(olddir)
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local libraryfile   = os.tmpfile() .. ".a"
    local objectfile    = os.tmpfile() .. ".o"
    local sourcefile    = os.tmpfile() .. ".c"
    io.writefile(sourcefile, "int test(void)\n{return 0;}")

    -- make flags
    local arflags = table.concat(_g.arflags, " ")
    if flags then
        arflags = arflags .. " " .. flags
    end

    -- compile it
    compiler.compile(sourcefile, objectfile)

    -- check it
    link(objectfile, "static", libraryfile, arflags)

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
    os.rm(libraryfile)
end
