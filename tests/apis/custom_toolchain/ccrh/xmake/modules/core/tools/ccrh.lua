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
-- @author      retro98boy
-- @file        ccrh.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.policy")
import("core.language.language")
import("utils.progress")

-- init it
function init(self)
end

-- make the symbol flag
function nf_symbol(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps = _g.symbol_maps
        if not maps then
            maps =
            {
                debug  = "-g"
            }
            _g.symbol_maps = maps
        end
        return maps[level .. '_' .. kind] or maps[level]
    end
end

-- make the optimize flag
function nf_optimize(self, level)
    local maps =
    {
        none       = "-Onothing"
    ,   fast       = "-Ospeed"
    ,   faster     = "-Ospeed"
    ,   fastest    = "-Ospeed"
    ,   smallest   = "-Osize"
    ,   aggressive = "-Ospeed"
    }
    return maps[level]
end

-- make the language flag
function nf_language(self, stdname)

    -- the stdc maps
    if _g.cmaps == nil then
        _g.cmaps =
        {
            ansi        = "-lang=c"
        ,   c89         = "-lang=c"
        ,   gnu89       = "-lang=c"
        ,   c99         = "-lang=c99"
        ,   gnu99       = "-lang=c99"
        ,   clatest     = {"-lang=c99", "-lang=c"}
        ,   gnulatest   = {"-lang=c99", "-lang=c"}
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

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return self:program(), table.join("-c", flags, "-o" .. objectfile, sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags, opt)
    os.mkdir(path.directory(objectfile))
    local depfile = dependinfo and os.tmpfile() or nil
    try
    {
        function ()
            local compflags = flags
            local outdata, errdata = os.iorunv(compargv(self, sourcefile, objectfile, compflags))
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
                if warnings and #warnings > 0 and policy.build_warnings(opt) then
                    if progress.showing_without_scroll() then
                        print("")
                    end
                    cprint("${color.warning}%s", table.concat(table.slice(warnings:split('\n'), 1, 8), '\n'))
                end

                -- generate the dependent includes
                if depfile and os.isfile(depfile) then
                    if dependinfo then
                        dependinfo.depfiles_format = "ccrh"
                        dependinfo.depfiles = io.readfile(depfile, {continuation = "\\"})
                    end

                    -- remove the temporary dependent file
                    os.tryrm(depfile)
                end
            end
        }
    }
end
