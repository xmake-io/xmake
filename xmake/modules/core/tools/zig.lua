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
-- @file        zig.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.project.target")

-- init it
function init(self)

    -- init shflags
    self:set("zcshflags", "-dynamic", "-fPIC")

    -- init zcflags for the kind: shared
    self:set("shared.zcflags", "-fPIC")
end

-- make the strip flag
function nf_strip(self, level)
    local maps = {
        debug  = "-fstrip"
    ,   all    = {"-fstrip", "-dead_strip"}
    }
    return maps[level]
end

-- make the define flag
function nf_define(self, macro)
    return "-D" .. macro
end

-- make the optimize flag
function nf_optimize(self, level)
    local maps =
    {
        none       = "-O Debug"
    ,   fast       = "-O ReleaseSafe"
    ,   fastest    = "-O ReleaseFast"
    ,   smallest   = "-O ReleaseSmall"
    ,   aggressive = "-O ReleaseFast"
    }
    return maps[level]
end

-- make the link flag
function nf_link(self, lib)
    return "-l" .. lib
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return {"-L", dir}
end

-- make the framework flag
function nf_framework(self, framework)
    return {"-framework", framework}
end

-- make the frameworkdir flag
function nf_frameworkdir(self, frameworkdir)
    return {"-F", path.translate(frameworkdir)}
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    dir = path.translate(dir)
    if self:is_plat("macosx") then
        return {"-rpath", (dir:gsub("%$ORIGIN", "@loader_path"))}
    else
        return {"-rpath", (dir:gsub("@[%w_]+", function (name)
            local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
            return maps[name]
        end))}
    end
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)
    local argv = {}
    if targetkind == "binary" then
        table.insert(argv, "build-exe")
    elseif targetkind == "static" or targetkind == "shared" then
        table.insert(argv, "build-lib")
    else
        raise("unknown target kind(%s)!", targetkind)
    end
    table.join2(argv, flags, "-femit-bin=" .. targetfile, objectfiles)
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return self:program(), table.join("build-obj", flags, "-femit-bin=" .. objectfile, sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)
    os.mkdir(path.directory(objectfile))
    os.runv(compargv(self, sourcefile, objectfile, flags))
end

