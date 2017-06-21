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
-- @file        rc.lua
--

-- imports
import("core.base.option")
import("core.project.project")

-- init it
function init(program, kind)
    
    -- save the shell name
    _g.program = program or "rc.exe"

    -- save kind
    _g.kind = kind

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

-- make the define flag
function nf_define(macro)

    -- make it
    return "-d" .. macro:gsub("\"", "\\\"")
end

-- make the undefine flag
function nf_undefine(macro)

    -- make it
    return "-u" .. macro
end

-- make the includedir flag
function nf_includedir(dir)

    -- make it
    return "-I" .. dir
end

-- make the complie command
function _compcmd1(sourcefile, objectfile, flags)

    -- make it
    return format("%s %s -Fo%s %s", _g.program, flags, objectfile, sourcefile)
end

-- complie the source file
function _compile1(sourcefile, objectfile, incdepfile, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    try
    {
        function ()
            local outdata, errdata = os.iorun(_compcmd1(sourcefile, objectfile, flags))
            return (outdata or "") .. (errdata or "")
        end,
        catch
        {
            function (errors)

                -- compiling errors
                os.raise(errors)
            end
        },
        finally
        {
            function (ok, warnings)

                -- print some warnings
                if warnings and #warnings > 0 and option.get("verbose") then
                    cprint("${yellow}%s", table.concat(table.slice(warnings:split('\n'), 1, 8), '\n'))
                end
            end
        }
    }
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

    -- make an stub source file
    local objectfile = os.tmpfile() .. ".res"
    local sourcefile = os.tmpfile() .. ".rc"
    io.writefile(sourcefile, "#define RESID 1")

    -- check it
    os.run("%s -fo%s %s", _g.program, objectfile, sourcefile)

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
end

