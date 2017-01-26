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
-- @file        gcc.lua
--

-- imports
import("core.tool.tool")
import("core.base.option")
import("core.project.config")
import("core.project.project")

-- init it
function init(shellname, kind)
    
    -- save the shell name
    _g.shellname = shellname or "gcc"

    -- save the kind
    _g.kind = kind

    -- init mxflags
    _g.mxflags = {  "-fmessage-length=0"
                ,   "-pipe"
                ,   "-fpascal-strings"
                ,   "\"-DIBOutlet=__attribute__((iboutlet))\""
                ,   "\"-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))\""
                ,   "\"-DIBAction=void)__attribute__((ibaction)\""}

    -- init shflags
    _g.shflags = { "-shared", "-fPIC" }

    -- init cxflags for the kind: shared
    _g.shared         = {}
    _g.shared.cxflags = {"-fPIC"}

    -- init flags map
    _g.mapflags = 
    {
        -- warnings
        ["-W1"] = "-Wall"
    ,   ["-W2"] = "-Wall"
    ,   ["-W3"] = "-Wall"

         -- strip
    ,   ["-s"]  = "-s"
    ,   ["-S"]  = "-S"

    }
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

-- make the symbol flag
function symbol(level)

    -- the maps
    local maps = 
    {   
        debug       = "-g"
    ,   hidden      = "-fvisibility=hidden"
    }

    -- make it
    return maps[level] or ""
end

-- make the warning flag
function warning(level)

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
function optimize(level)

    -- the maps
    local maps = 
    {   
        none        = "-O0"
    ,   fast        = "-O1"
    ,   faster      = "-O2"
    ,   fastest     = "-O3"
    ,   smallest    = "-Os"
    ,   aggressive  = "-Ofast"
    }

    -- make it
    return maps[level] or ""
end

-- make the vector extension flag
function vectorext(extension)

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

-- make the language flag
function language(stdname)

    -- the stdc maps
    local cmaps = 
    {
        -- stdc
        ansi        = "-ansi"
    ,   c89         = "-std=c89"
    ,   gnu89       = "-std=gnu89"
    ,   c99         = "-std=c99"
    ,   gnu99       = "-std=gnu99"
    ,   c11         = "-std=c11"
    ,   gnu11       = "-std=gnu11"
    }

    -- the stdc++ maps
    local cxxmaps = 
    {
        cxx98       = "-std=c++98"
    ,   gnuxx98     = "-std=gnu++98"
    ,   cxx11       = "-std=c++11"
    ,   gnuxx11     = "-std=gnu++11"
    ,   cxx14       = "-std=c++14"
    ,   gnuxx14     = "-std=gnu++14"
    }

    -- select maps
    local maps = cmaps
    if _g.kind == "cxx" or _g.kind == "mxx" then
        maps = cxxmaps
    elseif _g.kind == "sc" then
        maps = {}
    end

    -- make it
    return maps[stdname] or ""
end

-- make the define flag
function define(macro)

    -- make it
    return "-D" .. macro:gsub("\"", "\\\"")
end

-- make the undefine flag
function undefine(macro)

    -- make it
    return "-U" .. macro
end

-- make the includedir flag
function includedir(dir)

    -- make it
    return "-I" .. dir
end

-- make the linklib flag
function linklib(lib)

    -- make it
    return "-l" .. lib
end

-- make the linkdir flag
function linkdir(dir)

    -- make it
    return "-L" .. dir
end

-- make the link command
function linkcmd(objectfiles, targetfile, flags)

    -- make it
    return format("%s -o %s %s %s", _g.shellname, targetfile, objectfiles, flags)
end

-- make the complie command
function compcmd(sourcefile, objectfile, flags)

    -- get ccache
    local ccache = nil
    if config.get("ccache") then
        ccache = tool.shellname("ccache")
    end

    -- make it
    local command = format("%s -c %s -o %s %s", _g.shellname, flags, objectfile, sourcefile)
    if ccache then
        command = ccache:append(command, " ")
    end

    -- ok
    return command
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
    try
    {
        function ()
            local outdata, errdata = os.iorun(compcmd(sourcefile, objectfile, flags))
            return (outdata or "") .. (errdata or "")
        end,
        finally
        {
            function (ok, errors)

                -- parse warnings and errors
                local errinfos  = nil
                local warnings  = nil
                for _, errline in ipairs(errors:split('\n')) do
                    if errinfos or errline:find("%serror:") then
                        errinfos = errinfos or {}
                        table.insert(errinfos, errline)
                    else
                        warnings = warnings or {}
                        if #warnings < 8 then
                            table.insert(warnings, errline)
                        end
                    end
                end

                -- print some warnings
                if warnings and option.get("verbose") then
                    cprint("${yellow}%s", table.concat(warnings, '\n'))
                end

                -- raise errors
                if errinfos then
                    os.raise(table.concat(errinfos, '\n'))
                end
            end
        }
    }

    -- generate includes file
    if incdepfile and _g.kind ~= "as" then

        -- the temporary file
        local tmpfile = os.tmpfile()

        -- generate it
        os.run("%s -c -MM %s -o %s %s", _g.shellname, flags or "", tmpfile, sourcefile)

        -- translate it
        local results = {}
        local incdeps = io.read(tmpfile)
        for includefile in string.gmatch(incdeps, "%s+([%w/%.%-%+_%$%.]+)") do

            -- save it if belong to the project
            if not path.is_absolute(includefile) then
                table.insert(results, includefile)
            end
        end

        -- update it
        io.save(incdepfile, results)

        -- remove the temporary file
        os.rm(tmpfile)
    end
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local objectfile = os.tmpfile() .. ".o"
    local sourcefile = os.tmpfile() .. ".c" .. ifelse(_g.kind == "cxx", "pp", "")

    -- make stub code
    io.write(sourcefile, "int main(int argc, char** argv)\n{return 0;}")

    -- check it
    os.run("%s -c %s -o %s %s", _g.shellname, ifelse(flags, flags, ""), objectfile, sourcefile)

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
end

