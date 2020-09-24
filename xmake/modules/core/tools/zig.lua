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
    local maps =
    {
        debug       = "--strip"
    ,   all         = "--strip"
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
        none       = "-O0"
    ,   fast       = "--release-safe"
    ,   aggressive = "--release-fast"
    ,   fastest    = "--release-fast"
    ,   smallest   = "--release-small"
    ,   aggressive = "--release-fast"
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
    return "-L" .. os.args(dir)
end

-- make the framework flag
function nf_framework(self, framework)
    return "-framework " .. framework
end

-- make the frameworkdir flag
function nf_frameworkdir(self, frameworkdir)
    return "-F " .. os.args(path.translate(frameworkdir))
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    dir = path.translate(dir)
    if is_plat("macosx") then
        return "-rpath " .. os.args(dir:gsub("%$ORIGIN", "@loader_path"))
    else
        return "-rpath " .. os.args(dir:gsub("@[%w_]+", function (name)
            local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
            return maps[name]
        end))
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
    local name = targetkind == "binary" and path.basename(targetfile) or target.linkname(path.filename(targetfile))
    table.join2(argv, flags, "--output-dir", path.directory(targetfile), "--name", name)
    for _, objectfile in ipairs(objectfiles) do
        table.insert(argv, "--object")
        table.insert(argv, objectfile)
    end
    return self:program(), argv
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
    return self:program(), table.join("build-obj", flags, "--output-dir", path.directory(objectfile), "--name", path.basename(objectfile), sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.runv(compargv(self, sourcefile, objectfile, flags))
end

