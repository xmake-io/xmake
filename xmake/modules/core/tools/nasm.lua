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
-- @file        nasm.lua
--

-- imports
import("core.base.option")
import("core.language.language")

-- init it
function init(self)

    -- init flags map
    self:set("mapflags",
    {
        -- symbols
        ["-g"]                      = ""
    ,   ["-fvisibility=.*"]         = ""

        -- warnings
    ,   ["-Wall"]                   = "" -- = "-Wall" will enable too more warnings
    ,   ["-W1"]                     = ""
    ,   ["-W2"]                     = ""
    ,   ["-W3"]                     = ""
    ,   ["-Werror"]                 = ""
    ,   ["%-Wno%-error=.*"]         = ""

        -- others
    ,   ["-ftrapv"]                 = ""
    ,   ["-fsanitize=address"]      = ""
    })
end

-- make the symbol flag
function nf_symbol(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps = {
            debug  = "-g"
        }
        return maps[level]
    end
end

-- make the warning flag
function nf_warning(self, level)
    local maps = {
        none  = "-w"
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
    return {"-I", dir}
end

-- make the sysincludedir flag
function nf_sysincludedir(self, dir)
    return nf_includedir(self, dir)
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return self:program(), table.join(flags, "-o", objectfile, sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    local outdata, errdata = try
    {
        function ()
            return os.iorunv(compargv(self, sourcefile, objectfile, flags))
        end,
        catch
        {
            function (errors)

                -- try removing the old object file for forcing to rebuild this source file
                os.tryrm(objectfile)

                -- raise compiling errors
                raise(tostring(errors))
            end
        },
        finally
        {
            function (ok, outdata, errdata)

                -- show warnings?
                if ok and errdata and (option.get("diagnosis") or option.get("warning")) then
                    errdata = errdata:trim()
                    if #errdata > 0 then
                        cprint("${color.warning}%s", errdata)
                    end
                end
            end
        }
    }
end

