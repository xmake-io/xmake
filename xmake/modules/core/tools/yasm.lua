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
-- @file        yasm.lua
--

-- imports
import("core.base.option")

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

-- make the warning flag
function nf_warning(self, level)

    -- the maps
    local maps =
    {
        none  = "-w"
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

-- make the compile arguments list
function _compargv1(self, sourcefile, objectfile, flags)
    return self:program(), table.join(flags, "-o", objectfile, sourcefile)
end

-- compile the source file
function _compile1(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    local outdata, errdata = try
    {
        function ()
            return os.iorunv(_compargv1(self, sourcefile, objectfile, flags))
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

