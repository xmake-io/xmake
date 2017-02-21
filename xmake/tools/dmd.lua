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
import("core.tool.tool")
import("core.base.option")
import("core.project.config")
import("core.project.project")

-- init it
function init(shellname, kind)
    
    -- save the shell name
    _g.shellname = shellname or "dmd"

    -- save the kind
    _g.kind = kind

    -- init features
    _g.features = 
    {
        ["compile:multifiles"] = false
    }
end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the includedir flag
function nf_includedir(dir)

    -- make it
    return ""
end

-- make the linkdir flag
function nf_linkdir(dir)

    -- make it
    return ""
end

-- make the link command
function linkcmd(objectfiles, targetkind, targetfile, flags)

    -- kinds
    local kinds = 
    {
        static = " -lib"
    ,   shared = " -shared"
    }

    -- make it
    return format("%s%s %s -of%s %s", _g.shellname, kinds[targetkind] or "", flags, targetfile, objectfiles)
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
    return format("%s -c %s -of%s %s", _g.shellname, flags, objectfile, table.concat(table.wrap(sourcefiles), " "))
end

-- complie the source file
function compile(sourcefiles, objectfile, incdepfile, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.run(compcmd(sourcefiles, objectfile, flags))
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local objectfile = os.tmpfile() .. ".o"
    local sourcefile = os.tmpfile() .. ".d"

    -- make stub code
    io.write(sourcefile, "void main() {\n}")

    -- check it
    os.run("%s -c %s -of%s %s", _g.shellname, ifelse(flags, flags, ""), objectfile, sourcefile)

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
end
