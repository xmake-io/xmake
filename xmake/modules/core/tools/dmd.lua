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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        dmd.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- init it
function init(self)

    -- init arflags
    self:set("dcarflags", "-lib")

    -- init shflags
    self:set("dcshflags", "-shared")

    -- add -fPIC for shared
    if not self:is_plat("windows", "mingw") then
        self:add("dcshflags", "-fPIC")
        self:add("shared.dcflags", "-fPIC")
    end
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
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
end

-- make the strip flag
function nf_strip(self, level)
    if not self:is_plat("windows") then
        local maps = {
            debug = "-L-S",
            all   = "-L-s"
        }
        return maps[level]
    end
end

-- make the symbol flag
function nf_symbol(self, level)
    local maps = {
        debug = "-g -debug"
    }
    return maps[level]
end

-- make the warning flag
function nf_warning(self, level)
    local maps = {
        none        = "-d",
        less        = "-w",
        more        = "-w -wi",
        all         = "-w -wi",
        everything  = "-w -wi",
        error       = "-de"
    }
    return maps[level]
end

-- make the vector extension flag
function nf_vectorext(self, extension)
    local maps = {
        avx  = "-mcpu=avx",
        avx2 = "-mcpu=avx"
    }
    return maps[extension]
end

-- make the includedir flag
function nf_includedir(self, dir)
    return {"-I" .. dir}
end

-- make the sysincludedir flag
function nf_sysincludedir(self, dir)
    return nf_includedir(self, dir)
end

-- make the link flag
function nf_link(self, lib)
    if self:is_plat("windows") then
        return "-L" .. lib .. ".lib"
    else
        return "-L-l" .. lib
    end
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    if self:is_plat("windows") then
        return {"-L-libpath:" .. dir}
    else
        return {"-L-L" .. dir}
    end
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    if not self:is_plat("windows") then
        dir = path.translate(dir)
        if self:has_flags("-L-rpath=" .. dir, "ldflags") then
            return {"-L-rpath=" .. (dir:gsub("@[%w_]+", function (name)
                local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
                return maps[name]
            end))}
        elseif self:has_flags("-L-rpath -L" .. dir, "ldflags") then
            return {"-L-rpath", "-L" .. (dir:gsub("%$ORIGIN", "@loader_path"))}
        end
    end
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)

    -- add rpath for dylib (macho), e.g. -install_name @rpath/file.dylib
    local flags_extra = {}
    if targetkind == "shared" and self:is_plat("macosx") then
        table.insert(flags_extra, "-L-install_name")
        table.insert(flags_extra, "-L@rpath/" .. path.filename(targetfile))
    end

    -- init arguments
    return self:program(), table.join(flags, flags_extra, "-of" .. targetfile, objectfiles)
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return self:program(), table.join("-c", flags, "-of" .. objectfile, sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)
    os.mkdir(path.directory(objectfile))
    os.runv(compargv(self, sourcefile, objectfile, flags))
end

