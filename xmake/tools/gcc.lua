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
import("detect.tools.find_ccache")

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
    _g.shared          = {}
    _g.shared.cxflags  = {"-fPIC"}

    -- suppress warning for clang (gcc -> clang on macosx) 
    if try { function () check("-Qunused-arguments"); return true end } then
        _g.cxflags = {"-Qunused-arguments"}
        _g.mxflags = {"-Qunused-arguments"}
        _g.asflags = {"-Qunused-arguments"}
    end

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

-- make the strip flag
function nf_strip(level)

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
function nf_symbol(level)

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

-- make the language flag
function nf_language(stdname)

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
    ,   cxx1z       = "-std=c++1z"
    ,   gnuxx1z     = "-std=gnu++1z"
    ,   cxx17       = "-std=c++17"
    ,   gnuxx17     = "-std=gnu++17"
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
function nf_define(macro)

    -- make it
    return "-D" .. macro:gsub("\"", "\\\"")
end

-- make the undefine flag
function nf_undefine(macro)

    -- make it
    return "-U" .. macro
end

-- make the includedir flag
function nf_includedir(dir)

    -- make it
    return "-I" .. dir
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

-- make the rpathdir flag
function nf_rpathdir(dir)

    -- check this flag
    local flag = "-Wl,-rpath=" .. dir
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

-- make the framework flag
function nf_framework(framework)

    -- make it
    return "-framework " .. framework
end

-- make the link command
function linkcmd(objectfiles, targetkind, targetfile, flags)

    -- make it
    return format("%s -o %s %s %s", _g.shellname, targetfile, objectfiles, flags)
end

-- link the target file
function link(objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.run(linkcmd(objectfiles, targetkind, targetfile, flags))
end

-- make the complie command
function _compcmd1(sourcefile, objectfile, flags)

    -- get ccache
    local ccache = nil
    if config.get("ccache") then
        ccache = find_ccache()
    end

    -- make it
    local command = format("%s -c %s -o %s %s", _g.shellname, flags, objectfile, sourcefile)
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

    -- generate includes file
    if incdepfile and _g.kind ~= "as" then

        -- the temporary file
        local tmpfile = os.tmpfile()

        -- generate it
        os.run("%s -c -MM %s -o %s %s", _g.shellname, flags or "", tmpfile, sourcefile)

        -- translate it
        local results = {}
        local incdeps = io.readfile(tmpfile)
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
function check(flags, trylink)

    -- make an stub source file
    local binaryfile = os.tmpfile() .. ".b"
    local objectfile = os.tmpfile() .. ".o"
    local sourcefile = os.tmpfile() .. ".c" .. ifelse(_g.kind == "cxx", "pp", "")

    -- make stub code
    io.writefile(sourcefile, "int main(int argc, char** argv)\n{return 0;}")

    -- check it, need check compflags and linkflags
    if trylink then
        os.run("%s %s -o %s %s", _g.shellname, ifelse(flags, flags, ""), binaryfile, sourcefile)
    else
        os.run("%s -c %s -o %s %s", _g.shellname, ifelse(flags, flags, ""), binaryfile, sourcefile)
    end

    -- remove files
    os.tryrm(binaryfile)
    os.tryrm(objectfile)
    os.tryrm(sourcefile)
end

