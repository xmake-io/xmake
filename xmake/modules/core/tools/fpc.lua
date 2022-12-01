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
-- @file        fpc.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- init it
function init(self)
    if not self:is_plat("windows", "mingw") then
        self:add("shared.pcflags", "-Cg")
    end
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps =
        {
            none       = "-O-"
        ,   fast       = "-O1"
        ,   fastest    = "-O3"
        ,   smallest   = "-O2"
        ,   aggressive = "-O4"
        }
        return maps[level]
    end
end

-- make the strip flag
function nf_strip(self, level)
    if level == "all" then
        return "-Xs"
    end
end

-- make the symbol flag
function nf_symbol(self, level)
    if level == "debug" and self:kind() == "pc" then
        if self:is_plat("windows") then
            return {"-gw3", "-WN"}
        else
            return "-gw3"
        end
    end
end

-- make the link flag
function nf_link(self, lib)
    return "-k-l" .. lib
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return {"-k-L" .. dir}
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    dir = path.translate(dir)
    if self:has_flags("-k-rpath=" .. dir, "ldflags") then
        return {"-k-rpath=" .. (dir:gsub("@[%w_]+", function (name)
            local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
            return maps[name]
        end))}
    end
end

-- make the framework flag
function nf_framework(self, framework)
    return {"-k-framework", framework}
end

-- make the frameworkdir flag
function nf_frameworkdir(self, frameworkdir)
    return {"-k-F", path.translate(frameworkdir)}
end

-- make the build arguments list
function buildargv(self, sourcefiles, targetkind, targetfile, flags)
    return self:program(), table.join(flags, "-o" .. targetfile, sourcefiles)
end

-- build the target file
function build(self, sourcefiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    os.runv(buildargv(self, sourcefiles, targetkind, targetfile, flags))
end

