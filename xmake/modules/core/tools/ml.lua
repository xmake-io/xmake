--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        ml.lua
--

-- imports
import("private.tools.vstool")

-- init it
--
-- @see https://docs.microsoft.com/en-us/cpp/assembler/masm/ml-and-ml64-command-line-reference
--
function init(self)
   
    -- init asflags
    if self:program():find("64") then
        self:set("asflags", "-nologo")
    else
        self:set("asflags", "-nologo", "-Gd")
    end

    -- init flags map
    self:set("mapflags", 
    {
        -- symbols
        ["-g"]                      = "-Z7"
    ,   ["-fvisibility=.*"]         = ""

        -- warnings
    ,   ["-W1"]                     = "-W1"
    ,   ["-W2"]                     = "-W2"
    ,   ["-W3"]                     = "-W3"
    ,   ["-Wall"]                   = "-W3" -- /W level 	Sets the warning level, where level = 0, 1, 2, or 3.
    ,   ["-Wextra"]                 = "-W3"
    ,   ["-Weverything"]            = "-W3"
    ,   ["-Werror"]                 = "-WX"
    ,   ["%-Wno%-error=.*"]         = ""

        -- others
    ,   ["-ftrapv"]                 = ""
    ,   ["-fsanitize=address"]      = ""
    })
end

-- make the warning flag
function nf_warning(self, level)

    -- the maps
    local maps = 
    {   
        none         = "-w"
    ,   less         = "-W1"
    ,   more         = "-W3"
    ,   all          = "-W3"
    ,   everything   = "-W3"
    ,   error        = "-WX"
    }

    -- make it
    return maps[level] 
end

-- make the define flag
function nf_define(self, macro)
    return "-D" .. macro
end

-- make the undefine flag
function nf_undefine(self, macro)
    return "-U" .. macro
end

-- make the includedir flag
function nf_includedir(self, dir)
    return "-I" .. os.args(dir)
end

-- make the compile arguments list
function _compargv1(self, sourcefile, objectfile, flags)
    return self:program(), table.join("-c", flags, "-Fo" .. objectfile, sourcefile)
end

-- compile the source file
function _compile1(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- use vstool to compile and enable vs_unicode_output @see https://github.com/xmake-io/xmake/issues/528
    vstool.runv(_compargv1(self, sourcefile, objectfile, flags))
end

-- make the compile arguments list
function compargv(self, sourcefiles, objectfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    return _compargv1(self, sourcefiles, objectfile, flags)
end

-- compile the source file
function compile(self, sourcefiles, objectfile, dependinfo, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    _compile1(self, sourcefiles, objectfile, dependinfo, flags)
end

