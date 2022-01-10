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
-- @file        ml.lua
--

-- imports
import("private.tools.vstool")
import("core.base.hashset")

-- init it
--
-- @see https://docs.microsoft.com/en-us/cpp/assembler/masm/ml-and-ml64-command-line-reference
--
function init(self)

    -- init asflags
    self:set("asflags", "-nologo")

    -- init flags map
    self:set("mapflags",
    {
        -- symbols
        ["-g"]                      = "-Z7"
    ,   ["-fvisibility=.*"]         = ""

        -- warnings
    ,   ["-W1"]                     = "-W1"
    ,   ["-W2"]                     = "-W2"
    ,   ["-W3"]                     = "-W3"
    ,   ["-Wall"]                   = "-W3" -- /W level 	Sets the warning level, where level = 0, 1, 2, or 3.
    ,   ["-Wextra"]                 = "-W3"
    ,   ["-Weverything"]            = "-W3"
    ,   ["-Werror"]                 = "-WX"
    ,   ["%-Wno%-error=.*"]         = ""

        -- others
    ,   ["-ftrapv"]                 = ""
    ,   ["-fsanitize=address"]      = ""
    })
end

-- make the symbol flags
function nf_symbols(self, levels, target)
    local flags = nil
    local values = hashset.from(levels)
    if values:has("debug") then
        flags = {}
        if values:has("edit") then
            table.insert(flags, "-ZI")
        elseif values:has("embed") then
            table.insert(flags, "-Z7")
        else
            table.insert(flags, "-Zi")
        end
    end
    return flags
end

-- make the warning flag
function nf_warning(self, level)
    local maps =
    {
        none         = "-w"
    ,   less         = "-W1"
    ,   more         = "-W3"
    ,   all          = "-W3"
    ,   everything   = "-W3"
    ,   error        = "-WX"
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

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    -- we need to set the default -Gd option for the x86 architecture,
    -- if the other calling convention flags are not set
    --
    -- we can't directly remove -Gd. This is not only for backward compatibility,
    -- but also to simplify mixed compilation with c programs.
    --
    -- although this may affect some performance,
    -- it only takes effect under x86 asm, so there will be no major performance issues.
    --
    -- @see https://github.com/xmake-io/xmake/issues/1779
    --
    if not self:program():find("64", 1, true) and
        not table.contains(flags, "-Gc", "/Gc", "-GZ", "/GZ") then
        table.insert(flags, "-Gd")
    end
    return self:program(), table.join("-c", flags, "-Fo" .. objectfile, sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    try
    {
        function ()
            -- @note we need not uses vstool.runv to enable unicode output for ml.exe
            local program, argv = compargv(self, sourcefile, objectfile, flags)
            os.runv(program, argv, {envs = self:runenvs()})
        end,
        catch
        {
            function (errors)

                -- use link/stdout as errors first from vstool.iorunv()
                if type(errors) == "table" then
                    local errs = errors.stdout or ""
                    if #errs:trim() == 0 then
                        errs = errors.stderr or ""
                    end
                    errors = errs
                end
                raise(tostring(errors))
            end
        }
    }
end

