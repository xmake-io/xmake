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
-- @file        clang_cl.lua
--

-- inherit cl
inherit("cl")
import("core.base.option")
import("core.base.colors")

-- init it
function init(self)
    _super.init(self)
end

-- has color diagnostics?
function _has_color_diagnostics(self)
    local colors_diagnostics = _g._HAS_COLOR_DIAGNOSTICS
    if colors_diagnostics == nil then
        if io.isatty() and (colors.color8() or colors.color256()) then
            local theme = colors.theme()
            if theme and theme:name() ~= "plain" then
                -- for clang
                if self:has_flags("-fcolor-diagnostics", "cxflags") then
                    colors_diagnostics = "-fcolor-diagnostics"
                -- for gcc
                elseif self:has_flags("-fdiagnostics-color=always", "cxflags") then
                    colors_diagnostics = "-fdiagnostics-color=always"
                end
            end
        end
        colors_diagnostics = colors_diagnostics or false
        _g._HAS_COLOR_DIAGNOSTICS = colors_diagnostics
    end
    return colors_diagnostics
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    -- @note this path here has been normalized, we can quickly find it by the unique path separator prompt
    os.mkdir(path.directory(objectfile, path.sep()))

    -- compile it
    local outdata = try
    {
        function ()

            -- generate includes file
            local compflags = flags
            if dependinfo then
                compflags = table.join(flags, "-showIncludes")
            end

            -- has color diagnostics? enable it
            local colors_diagnostics = _has_color_diagnostics(self) 
            if colors_diagnostics then
                compflags = table.join(compflags, colors_diagnostics)
            end

            -- do compile
            return os.iorunv(compargv(self, sourcefile, objectfile, compflags))
        end,
        catch
        {
            function (errors)

                -- try removing the old object file for forcing to rebuild this source file
                os.tryrm(objectfile)

                -- parse and strip errors
                local lines = errors and tostring(errors):split('\n', {plain = true}) or {}
                if not option.get("verbose") then

                    -- find the start line of error
                    local start = 0
                    for index, line in ipairs(lines) do
                        if line:find("error:", 1, true) or line:find("错误：", 1, true) then
                            start = index
                            break
                        end
                    end

                    -- get 16 lines of errors
                    if start > 0 then
                        lines = table.slice(lines, start, start + ifelse(#lines - start > 16, 16, #lines - start))
                    end
                end

                -- raise compiling errors
                raise(#lines > 0 and table.concat(lines, "\n") or "")
            end
        },
        finally
        {
            function (ok, outdata, errdata)
                -- show warnings?
                if ok and errdata and #errdata > 0 and (option.get("diagnosis") or option.get("warning")) then
                    local lines = errdata:split('\n', {plain = true})
                    if #lines > 0 then
                        local warnings = table.concat(table.slice(lines, 1, ifelse(#lines > 8, 8, #lines)), "\n")
                        cprint("${color.warning}%s", warnings)
                    end
                end
            end
        }
    }

    -- generate the dependent includes
    if dependinfo and outdata then
        dependinfo.depfiles_cl = outdata
    end
end

