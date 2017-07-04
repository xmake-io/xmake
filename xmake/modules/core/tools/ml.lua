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
-- @file        ml.lua
--

-- init it
function init(self)
   
    -- init asflags
    if self:program():find("64") then
        _g.asflags = { "-nologo"}
    else
        _g.asflags = { "-nologo", "-Gd"}
    end

    -- init flags map
    _g.mapflags = 
    {
        -- symbols
        ["-g"]                      = "-Z7"
    ,   ["-fvisibility=.*"]         = ""

        -- warnings
    ,   ["-Wall"]                   = "-W3" -- = "-Wall" will enable too more warnings
    ,   ["-W1"]                     = "-W1"
    ,   ["-W2"]                     = "-W2"
    ,   ["-W3"]                     = "-W3"
    ,   ["-Werror"]                 = "-WX"
    ,   ["%-Wno%-error=.*"]         = ""

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

-- make the warning flag
function nf_warning(self, level)

    -- the maps
    local maps = 
    {   
        none        = "-w"
    ,   less        = "-W1"
    ,   more        = "-W3"
    ,   all         = "-W3"
    ,   error       = "-WX"
    }

    -- make it
    return maps[level] or ""
end

-- make the define flag
function nf_define(self, macro)
    return "-D" .. macro:gsub("\"", "\\\"")
end

-- make the undefine flag
function nf_undefine(self, macro)
    return "-U" .. macro
end

-- make the includedir flag
function nf_includedir(self, dir)
    return "-I" .. dir
end

-- make the complie command
function _compcmd1(self, sourcefile, objectfile, flags)
    return format("%s -c %s -Fo%s %s", self:program(), flags, objectfile, sourcefile)
end

-- complie the source file
function _compile1(self, sourcefile, objectfile, incdepfile, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.run(_compcmd1(self, sourcefile, objectfile, flags))
end

-- make the complie command
function compcmd(self, sourcefiles, objectfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    return _compcmd1(self, sourcefiles, objectfile, flags)
end

-- complie the source file
function compile(self, sourcefiles, objectfile, incdepfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    _compile1(self, sourcefiles, objectfile, incdepfile, flags)
end

