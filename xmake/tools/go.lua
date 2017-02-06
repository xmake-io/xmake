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
-- @file        go.lua
--

-- imports
import("core.tool.tool")
import("core.base.option")
import("core.project.config")
import("core.project.project")

-- init it
function init(shellname, kind)
    
    -- save the shell name
    _g.shellname = shellname or "go"

    -- save the kind
    _g.kind = kind

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the strip flag
function nf_strip(level)
    return ""
end

-- make the symbol flag
function nf_symbol(level)
    return ""
end

-- make the warning flag
function nf_warning(level)
    return ""
end

-- make the optimize flag
function nf_optimize(level)
    return ""
end

-- make the vector extension flag
function nf_vectorext(extension)
    return ""
end

-- make the language flag
function nf_language(stdname)
    return ""
end

-- make the define flag
function nf_define(macro)
    return ""
end

-- make the undefine flag
function nf_undefine(macro)
    return ""
end

-- make the includedir flag
function nf_includedir(dir)
    return ""
end

-- make the link flag
function nf_link(lib)
    return ""
end

-- make the linkdir flag
function nf_linkdir(dir)
    return ""
end

-- make the link command
function linkcmd(objectfiles, targetfile, flags)

    -- make it
    return format("%s tool link %s -o %s %s", _g.shellname, flags, targetfile, objectfiles)
end

-- make the complie command
function compcmd(sourcefile, objectfile, flags)

    -- make it
    return format("%s tool compile %s -o %s %s", _g.shellname, flags, objectfile, sourcefile)
end

-- link the target file
function link(objectfiles, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.run(linkcmd(objectfiles, targetfile, flags))
end

-- complie the source file
function compile(sourcefile, objectfile, incdepfile, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.run(compcmd(sourcefile, objectfile, flags))
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local objectfile = os.tmpfile() .. ".o"
    local sourcefile = os.tmpfile() .. ".go"

    -- make stub code
    io.write(sourcefile, "package main\nfunc main() {\n}")

    -- check it
    os.run("%s tool compile %s -o %s %s", _g.shellname, ifelse(flags, flags, ""), objectfile, sourcefile)

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
end

