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
-- @file        cparser.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")
import("private.tools.ccache")

-- init it
function init(self)

    -- init mxflags
    self:set("mxflags", "-fmessage-length=0"
                      , "-pipe"
                      , "-DIBOutlet=__attribute__((iboutlet))"
                      , "-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))"
                      , "-DIBAction=void)__attribute__((ibaction)")

    -- init shflags
    self:set("shflags", "-shared", "-fPIC")

    -- init cxflags for the kind: shared
    self:set("shared.cxflags", "-fPIC")

    -- init flags map
    self:set("mapflags",
    {
        -- warnings
        ["-W1"]          = "-Wall"
    ,   ["-W2"]          = "-Wall"
    ,   ["-W3"]          = "-Wall"
    ,   ["-W4"]          = "-Wall -Wextra"
    ,   ["-Weverything"] = "-Wall -Wextra"

         -- strip
    ,   ["-s"]  = "-s"
    ,   ["-S"]  = "-S"
    })
end

-- make the strip flag
function nf_strip(self, level)

    -- the maps
    local maps =
    {
        debug = "-S"
    ,   all   = "-s"
    }

    -- make it
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)

    -- the maps
    local maps =
    {
        debug  = "-g"
    ,   hidden = "-fvisibility=hidden"
    }

    -- make it
    return maps[level]
end

-- make the warning flag
function nf_warning(self, level)

    -- the maps
    local maps =
    {
        none       = "-w"
    ,   less       = "-Wall"
    ,   more       = "-Wall"
    ,   all        = "-Wall"
    ,   everything = "-Wextra -Wall"
    ,   error      = "-Werror"
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

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)
    return self:program(), table.join("-o", targetfile, objectfiles, flags)
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- make the compile arguments list
function _compargv1(self, sourcefile, objectfile, flags)
    return ccache.cmdargv(self:program(), table.join("-c", flags, "-o", objectfile, sourcefile))
end

-- compile the source file
function _compile1(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    try
    {
        function ()
            local outdata, errdata = os.iorunv(_compargv1(self, sourcefile, objectfile, flags))
            return (outdata or "") .. (errdata or "")
        end,
        catch
        {
            function (errors)

                -- try removing the old object file for forcing to rebuild this source file
                os.tryrm(objectfile)

                -- find the start line of error
                local lines = tostring(errors):split("\n")
                local start = 0
                for index, line in ipairs(lines) do
                    if line:find("error:", 1, true) or line:find("错误：", 1, true) then
                        start = index
                        break
                    end
                end

                -- get 16 lines of errors
                if start > 0 or not option.get("verbose") then
                    if start == 0 then start = 1 end
                    errors = table.concat(table.slice(lines, start, start + ifelse(#lines - start > 16, 16, #lines - start)), "\n")
                end

                -- raise compiling errors
                raise(errors)
            end
        },
        finally
        {
            function (ok, warnings)

                -- print some warnings
                if warnings and #warnings > 0 and (option.get("verbose") or option.get("warning")) then
                    cprint("${color.warning}%s", table.concat(table.slice(warnings:split('\n'), 1, 8), '\n'))
                end
            end
        }
    }
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

