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
-- @file        tcc.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- init it
function init(self)

    -- init shflags
    self:set("shflags", "-shared", "-rdynamic")

    -- init cxflags for the kind: shared
    self:set("shared.cxflags", "-fPIC")

    -- init flags map
    self:set("mapflags",
    {
        -- warnings
        ["-W1"] = "-Wall"
    ,   ["-W2"] = "-Wall"
    ,   ["-W3"] = "-Wall"
    ,   ["-W4"] = "-Wall -Wunsupported"

         -- strip
    ,   ["-s"]  = "-s"
    ,   ["-S"]  = "-S"
    })
end

-- make the strip flag
function nf_strip(self, level)
    local maps =
    {
        debug = "-S"
    ,   all   = "-s"
    }
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)
    local maps =
    {
        debug  = "-g"
    ,   hidden = "-fvisibility=hidden"
    }
    return maps[level]
end

-- make the warning flag
function nf_warning(self, level)
    local maps =
    {
        none       = "-w"
    ,   less       = "-W1"
    ,   more       = "-W3"
    ,   all        = "-Wall"
    ,   allextra   = "-Wall -Wunsupported -Wwrite-strings -Wimplicit-function-declaration"
    ,   everything = "-Wall -Wunsupported -Wwrite-strings -Wimplicit-function-declaration"
    ,   error      = "-Werror"
    }
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
    return {"-I" .. dir}
end

-- make the sysincludedir flag
function nf_sysincludedir(self, dir)
    return nf_includedir(self, dir)
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
    return {"-L" .. dir}
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)
    local argv
    if targetkind == "static" then
        argv = table.join("-ar", "cr", targetfile, objectfiles)
    else
        argv = table.join("-o", targetfile, objectfiles, flags)
    end
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return self:program(), table.join("-c", flags, "-o", objectfile, sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    try
    {
        function ()
            local outdata, errdata = os.iorunv(compargv(self, sourcefile, objectfile, flags))
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
                    errors = table.concat(table.slice(lines, start, start + ((#lines - start > 16) and 16 or (#lines - start))), "\n")
                end

                -- raise compiling errors
                raise(errors)
            end
        },
        finally
        {
            function (ok, warnings)

                -- print some warnings
                if warnings and #warnings > 0 and (option.get("verbose") or option.get("warning") or global.get("build_warning")) then
                    cprint("${color.warning}%s", table.concat(table.slice(warnings:split('\n'), 1, 8), '\n'))
                end
            end
        }
    }
end

