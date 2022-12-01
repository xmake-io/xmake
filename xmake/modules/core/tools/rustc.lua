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
-- @file        rustc.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- init it
function init(self)
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps =
        {
            none        = "-C opt-level=0"
        ,   fast        = "-C opt-level=1"
        ,   faster      = "-C opt-level=2"
        ,   fastest     = "-C opt-level=3"
        ,   smallest    = "-C opt-level=s"
        ,   aggressive  = "-C opt-level=z"
        }
        return maps[level]
    end
end

-- make the symbol flag
function nf_symbol(self, level)
    local maps =
    {
        debug = "-C debuginfo=2"
    }
    return maps[level]
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return {"-L" .. dir}
end

-- make the link flag
function nf_link(self, lib)
    return "-l" .. lib
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the frameworkdir flag, crate module dependency directories
function nf_frameworkdir(self, frameworkdir)
    return {"-L", "dependency=" .. frameworkdir}
end

-- make the framework flag, crate module
function nf_framework(self, framework)
    local basename = path.basename(framework)
    local cratename = basename:match("lib(.-)%-.-") or basename:match("lib(.-)")
    if cratename then
        return {"--extern", cratename .. "=" .. framework}
    end
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    dir = path.translate(dir)
    if self:has_flags({"-C", "link-arg=-Wl,-rpath=$ORIGIN"}, "ldflags") then
        return {"-C", "link-arg=-Wl,-rpath=" .. (dir:gsub("@[%w_]+", function (name)
            local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
            return maps[name]
        end))}
    elseif self:has_flags({"-C", "link-arg=-Xlinker", "-C", "link-arg=-rpath", "-C", "link-arg=-Xlinker", "-C", "link-arg=@loader_path"}, "ldflags") then
        return {"-C", "link-arg=-Xlinker",
                "-C", "link-arg=-rpath",
                "-C", "link-arg=-Xlinker",
                "-C", "link-arg=" .. (dir:gsub("%$ORIGIN", "@loader_path"))}
    end
end

-- make the build arguments list
function buildargv(self, sourcefiles, targetkind, targetfile, flags)
    -- add rpath for dylib (macho), e.g. -install_name @rpath/file.dylib
    local flags_extra = {}
    if targetkind == "shared" and self:is_plat("macosx", "iphoneos", "watchos") then
        table.insert(flags_extra, "-C")
        table.insert(flags_extra, "link-arg=-Xlinker")
        table.insert(flags_extra, "-C")
        table.insert(flags_extra, "link-arg=-install_name")
        table.insert(flags_extra, "-C")
        table.insert(flags_extra, "link-arg=-Xlinker")
        table.insert(flags_extra, "-C")
        table.insert(flags_extra, "link-arg=@rpath/" .. path.filename(targetfile))
    end
    return self:program(), table.join(flags, flags_extra, "-o", targetfile, sourcefiles)
end

-- build the target file
function build(self, sourcefiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    os.runv(buildargv(self, sourcefiles, targetkind, targetfile, flags))
end

-- make the compile arguments list
function compargv(self, sourcefiles, objectfile, flags)
    return self:program(), table.join("--emit", "obj", flags, "-o", objectfile, sourcefiles)
end

-- compile the source file
function compile(self, sourcefiles, objectfile, dependinfo, flags)
    os.mkdir(path.directory(objectfile))
    os.runv(compargv(self, sourcefiles, objectfile, flags))
end

