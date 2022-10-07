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
-- @file        nim.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- init it
--
-- @see https://nim-lang.org/docs/nimc.html
function init(self)

    -- init arflags
    self:set("ncarflags", "--app:staticlib", "--noMain")

    -- init shflags
    self:set("ncshflags", "--app:lib", "--noMain")
end

-- make the warning flag
function nf_warning(self, level)
    local maps =
    {
        none       = "--warning:X:off"
    ,   less       = "--warning:X:on"
    ,   more       = "--warning:X:on"
    ,   all        = "--warning:X:on"
    ,   allextra   = "--warning:X:on"
    ,   everything = "--warning:X:on"
    ,   error      = "--warningAsError:X:on"
    }
    return maps[level]
end

-- make the define flag
function nf_define(self, macro)
    return "--define:" .. macro
end

-- make the undefine flag
function nf_undefine(self, macro)
    return "--undef:" .. macro
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps =
        {
            none        = "--opt:none"
        ,   fast        = "-d:release"
        ,   faster      = "-d:release"
        ,   fastest     = "-d:release"
        ,   smallest    = {"-d:release", "--opt:size"}
        ,   aggressive  = "-d:danger"
        }
        return maps[level]
    end
end

-- make the symbol flag
function nf_symbol(self, level)
    local maps =
    {
        debug = "--debugger:native"
    }
    return maps[level]
end

-- make the strip flag
function nf_strip(self, level, target)
    if self:is_plat("linux", "macosx", "bsd") then
        if level == "debug" or level == "all" then
            return "--passL:-s"
        end
    end
end

-- make the includedir flag
function nf_includedir(self, dir)
    return {"--passC:-I" .. path.translate(dir)}
end

-- make the link flag
function nf_link(self, lib, target)
    if self:is_plat("windows") then
        return "--passL:" .. lib .. ".lib"
    else
        return "--passL:-l" .. lib
    end
end

-- make the linkdir flag
function nf_linkdir(self, dir, target)
    if self:is_plat("windows") then
        return {"--passL:-libpath:" .. path.translate(dir)}
    else
        return {"--passL:-L" .. path.translate(dir)}
    end
end

-- make the build arguments list
function buildargv(self, sourcefiles, targetkind, targetfile, flags)
    local flags_extra = {}
    if targetkind == "static" then
        -- fix multiple definition of `NimMain', it is only workaround solution
        -- we need to wait for this problem to be resolved
        --
        -- @see https://github.com/nim-lang/Nim/issues/15955
        local uniquekey = hash.uuid(targetfile):split("-", {plain = true})[1]
        table.insert(flags_extra, "--passC:-DNimMain=NimMain_" .. uniquekey)
        table.insert(flags_extra, "--passC:-DNimMainInner=NimMainInner_" .. uniquekey)
        table.insert(flags_extra, "--passC:-DNimMainModule=NimMainModule_" .. uniquekey)
        table.insert(flags_extra, "--passC:-DPreMain=PreMain_" .. uniquekey)
        table.insert(flags_extra, "--passC:-DPreMainInner=PreMainInner_" .. uniquekey)
    end
    if targetkind ~= "static" and self:is_plat("windows") then
        -- fix link flags for windows
        -- @see https://github.com/nim-lang/Nim/issues/19033
        local flags_new = {}
        local flags_link = {}
        for _, flag in ipairs(flags) do
            if flag:find("passL:", 1, true) then
                table.insert(flags_link, flag)
            else
                table.insert(flags_new, flag)
            end
        end
        if #flags_link > 0 then
            table.insert(flags_new, "--passL:-link")
            table.join2(flags_new, flags_link)
        end
        flags = flags_new
    end
    return self:program(), table.join("c", flags, flags_extra, "-o:" .. targetfile, sourcefiles)
end

-- build the target file
function build(self, sourcefiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    local program, argv = buildargv(self, sourcefiles, targetkind, targetfile, flags)
    os.runv(program, argv, {envs = self:runenvs()})
end


