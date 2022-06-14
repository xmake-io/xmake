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
-- @file        sdcc.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("utils.progress")
import("core.language.language")

-- init it
function init(self)

    -- init flags map
    self:set("mapflags",
    {
        -- optimize
        ["-O0"]                     = ""
    ,   ["-Os"]                     = "--opt-code-speed"
    ,   ["-O3"]                     = "--opt-code-size"
    ,   ["-Ofast"]                  = "--opt-code-speed"

        -- symbols
    ,   ["-fvisibility=.*"]         = ""

        -- warnings
    ,   ["-Weverything"]            = ""
    ,   ["-Wextra"]                 = ""
    ,   ["-Wall"]                   = ""
    ,   ["-W1"]                     = "--less-pedantic"
    ,   ["-W2"]                     = "--less-pedantic"
    ,   ["-W3"]                     = ""
    ,   ["%-Wno%-error=.*"]         = ""
    ,   ["%-fno%-.*"]               = ""

        -- language
    ,   ["-ansi"]                   = "--std-c89"
    ,   ["-std=c89"]                = "--std-c89"
    ,   ["-std=c99"]                = "--std-c99"
    ,   ["-std=c11"]                = "--std-c11"
    ,   ["-std=c20"]                = "--std-c2x"
    ,   ["-std=gnu89"]              = "--std-sdcc89"
    ,   ["-std=gnu99"]              = "--std-sdcc99"
    ,   ["-std=gnu11"]              = "--std-sdcc11"
    ,   ["-std=gnu20"]              = "--std-sdcc2x"
    ,   ["-std=.*"]                 = ""

        -- others
    ,   ["-ftrapv"]                 = ""
    ,   ["-fsanitize=address"]      = ""
    })
end

-- make the warning flag
function nf_warning(self, level)
    local maps =
    {
        none       = "--less-pedantic"
    ,   less       = "--less-pedantic"
    ,   error      = "-Werror"
    }
    return maps[level]
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps =
        {
            none       = ""
        ,   fast       = "--opt-code-speed"
        ,   faster     = "--opt-code-speed"
        ,   fastest    = "--opt-code-speed"
        ,   smallest   = "--opt-code-size"
        ,   aggressive = "--opt-code-speed"
        }
        return maps[level]
    end
end

-- make the language flag
function nf_language(self, stdname)
    if _g.cmaps == nil then
        _g.cmaps =
        {
            ansi        = "--std-c89"
        ,   c89         = "--std-c89"
        ,   gnu89       = "--std-sdcc89"
        ,   c99         = "--std-c99"
        ,   gnu99       = "--std-sdcc99"
        ,   c11         = "--std-c11"
        ,   gnu11       = "--std-sdcc11"
        ,   c20         = "--std-c2x"
        ,   gnu20       = "--std-sdcc2x"
        ,   clatest     = {"--std-c2x", "--std-c11", "--std-c99", "--std-c89"}
        ,   gnulatest   = {"--std-sdcc2x", "--std-sdcc11", "--std-sdcc99", "--std-sdcc89"}
        }
    end
    local maps = _g.cmaps
    local result = maps[stdname]
    if type(result) == "table" then
        for _, v in ipairs(result) do
            if self:has_flags(v, "cxflags") then
                result = v
                maps[stdname] = result
                return result
            end
        end
    else
        return result
    end
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
    return self:program(), table.join("-o", targetfile, objectfiles, flags)
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
                    if progress.showing_without_scroll() then
                        print("")
                    end
                    cprint("${color.warning}%s", table.concat(table.slice(warnings:split('\n'), 1, 8), '\n'))
                end
            end
        }
    }
end

