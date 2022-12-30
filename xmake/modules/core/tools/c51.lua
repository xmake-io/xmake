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
-- @author      DawnMagnet
-- @file        c51.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.language.language")
import("utils.progress")

-- init it
function init(self)
end

-- make the includedir flag
function nf_includedirs(self, dirs)
    local paths = {}
    for _, dir in ipairs(dirs) do
        table.insert(paths, path.translate(dir))
    end
    if #paths > 0 then
        return {"INCDIR(" .. table.concat(paths, ";") .. ")"}
    end
end

-- make the define flag
function nf_defines(self, defines)
    if defines and #defines > 0 then
        return {"DEFINE(" .. table.concat(defines, ",") .. ")"}
    end
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return self:program(), table.join(sourcefile, "OBJECT(" .. objectfile .. ")", "PRINT(" .. (objectfile:gsub("%.c%.obj", ".lst")) .. ")", flags)	
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

