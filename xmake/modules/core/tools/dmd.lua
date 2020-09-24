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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        dmd.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")

-- init it
function init(self)

    -- init arflags
    self:set("dcarflags", "-lib")

    -- init shflags
    self:set("dcshflags", "-shared", "-fPIC")

    -- init dcflags for the kind: shared
    self:set("shared.dcflags", "-fPIC")
end

-- make the optimize flag
function nf_optimize(self, level)
    local maps =
    {
        fast        = "-O"
    ,   faster      = "-O -release"
    ,   fastest     = "-O -release -inline -boundscheck=off"
    ,   smallest    = "-O -release -boundscheck=off"
    ,   aggressive  = "-O -release -inline -boundscheck=off"
    }
    return maps[level]
end

-- make the strip flag
function nf_strip(self, level)
    local maps =
    {
        debug       = "-L-S"
    ,   all         = "-L-s"
    }
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)
    local maps =
    {
        debug = "-g -debug"
    }
    return maps[level]
end

-- make the warning flag
function nf_warning(self, level)
    local maps =
    {
        none        = "-d"
    ,   less        = "-w"
    ,   more        = "-w -wi"
    ,   all         = "-w -wi"
    ,   everything  = "-w -wi"
    ,   error       = "-de"
    }
    return maps[level]
end

-- make the vector extension flag
function nf_vectorext(self, extension)
    local maps =
    {
        avx         = "-mcpu=avx"
    ,   avx2        = "-mcpu=avx"
    }
    return maps[extension]
end

-- make the includedir flag
function nf_includedir(self, dir)
    return "-I" .. os.args(dir)
end

-- make the link flag
function nf_link(self, lib)
    return "-L-l" .. lib
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return "-L-L" .. os.args(dir)
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    dir = path.translate(dir)
    if self:has_flags("-L-rpath=" .. dir, "ldflags") then
        return "-L-rpath=" .. os.args(dir:gsub("@[%w_]+", function (name)
            local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
            return maps[name]
        end))

    elseif self:has_flags("-L-rpath -L" .. dir, "ldflags") then
        return "-L-rpath -L" .. os.args(dir:gsub("%$ORIGIN", "@loader_path"))
    end
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)

    -- add rpath for dylib (macho), e.g. -install_name @rpath/file.dylib
    local flags_extra = {}
    if targetkind == "shared" and is_plat("macosx") then
        table.insert(flags_extra, "-L-install_name")
        table.insert(flags_extra, "-L@rpath/" .. path.filename(targetfile))
    end

    -- init arguments
    return self:program(), table.join(flags, flags_extra, "-of" .. targetfile, objectfiles)
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return self:program(), table.join("-c", flags, "-of" .. objectfile, sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.runv(compargv(self, sourcefile, objectfile, flags))
end

