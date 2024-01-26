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
import("core.project.policy")

-- init it
function init(self)
end

-- make the optimize flag
function nf_optimize(self, level)
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps = {
            fast       = "OT(8,SPEED)"
        ,   faster     = "OT(9,SPEED)"
        ,   fastest    = "OT(10,SPEED)"
        ,   smallest   = "OT(10,SIZE)"
        ,   aggressive = "OT(11,SPEED)"
        }
        return maps[level]
    end
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
    local lstfile = objectfile:gsub("%.c%.obj", ".lst")
    lstfile = lstfile:gsub("%.c%.o$", ".lst")
    return self:program(), table.join(sourcefile, "OBJECT(" .. objectfile .. ")", "PRINT(" .. lstfile .. ")", flags)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags, opt)
    os.mkdir(path.directory(objectfile))

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
            function (ok, outdata, errdata)
                -- show warnings?
                if ok and outdata and #outdata > 0 and policy.build_warnings(opt) then
                    local warnings_count = outdata:match("(%d-) WARNING")
                    if warnings_count and tonumber(warnings_count) > 0 then
                        local lines = outdata:split('\n', {plain = true})
                        if #lines > 0 then
                            if not option.get("diagnosis") then
                                lines = table.slice(lines, 1, (#lines > 16 and 16 or #lines))
                            end
                            local warnings = table.concat(lines, "\n")
                            if progress.showing_without_scroll() then
                                print("")
                            end
                            cprint("${color.warning}%s", warnings)
                        end
                    end
                end
            end
        }
    }
end

