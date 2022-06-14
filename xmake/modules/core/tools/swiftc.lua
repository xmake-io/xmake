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
-- @file        swiftc.lua
--

-- imports
import("core.project.config")
import("core.language.language")

-- init it
function init(self)

    -- init flags map
    self:set("mapflags",
    {
        -- symbols
        ["-fvisibility=hidden"]     = ""

        -- warnings
    ,   ["-w"]                      = "-suppress-warnings"
    ,   ["-W%d*"]                   = "-warn-swift3-objc-inference-minimal"
    ,   ["-Wall"]                   = "-warn-swift3-objc-inference-complete"
    ,   ["-Wextra"]                 = "-warn-swift3-objc-inference-complete"
    ,   ["-Weverything"]            = "-warn-swift3-objc-inference-complete"
    ,   ["-Werror"]                 = "-warnings-as-errors"

        -- optimize
    ,   ["-O0"]                     = "-Onone"
    ,   ["-Ofast"]                  = "-Ounchecked"
    ,   ["-O.*"]                    = "-O"

        -- vectorexts
    ,   ["-m.*"]                    = ""

        -- strip
    ,   ["-s"]                      = ""
    ,   ["-S"]                      = ""

        -- others
    ,   ["-ftrapv"]                 = ""
    ,   ["-fsanitize=address"]      = ""
    })
end

-- make the strip flag
function nf_strip(self, level)

    -- the maps
    local maps =
    {
        debug = "-Xlinker -S"
    ,   all   = "-Xlinker -s"
    }

    -- make it
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)

    -- the maps
    local maps =
    {
        debug = "-g"
    }

    -- make it
    return maps[level]
end

-- make the warning flag
function nf_warning(self, level)

    -- the maps
    local maps =
    {
        none       = "-suppress-warnings"
    ,   less       = "-warn-swift3-objc-inference-minimal"
    ,   more       = "-warn-swift3-objc-inference-minimal"
    ,   all        = "-warn-swift3-objc-inference-complete"
    ,   everything = "-warn-swift3-objc-inference-complete"
    ,   error      = "-warnings-as-errors"
    }

    -- make it
    return maps[level]
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps =
        {
            none        = "-Onone"
        ,   fast        = "-O"
        ,   faster      = "-O"
        ,   fastest     = "-O"
        ,   smallest    = "-O"
        ,   aggressive  = "-Ounchecked"
        }
        return maps[level]
    end
end

-- make the vector extension flag
function nf_vectorext(self, extension)

    -- the maps
    local maps =
    {
        mmx   = "-mmmx"
    ,   sse   = "-msse"
    ,   sse2  = "-msse2"
    ,   sse3  = "-msse3"
    ,   ssse3 = "-mssse3"
    ,   avx   = "-mavx"
    ,   avx2  = "-mavx2"
    ,   neon  = "-mfpu=neon"
    }

    -- make it
    return maps[extension]
end

-- make the define flag
function nf_define(self, macro)
    return {"-Xcc", "-D" .. macro}
end

-- make the undefine flag
function nf_undefine(self, macro)
    return {"-Xcc", "-U" .. macro}
end

-- make the framework flag
function nf_framework(self, framework)
    return {"-framework", framework}
end

-- make the frameworkdir flag
function nf_frameworkdir(self, frameworkdir)
    return {"-F", frameworkdir}
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
    return {"-L", dir}
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
    os.mkdir(path.directory(objectfile))
    os.runv(compargv(self, sourcefile, objectfile, flags))
end

