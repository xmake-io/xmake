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
-- @file        swift_frontend.lua
--

-- imports
import("core.project.config")
import("core.language.language")

-- init it
function init(self)

    -- init flags map
    self:set("mapflags", {

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

-- make the symbol flag
function nf_symbol(self, level)
    local maps = {
        debug = "-g"
    }
    return maps[level]
end

-- make the warning flag
function nf_warning(self, level)
    local maps = {
        none       = "-suppress-warnings"
    ,   less       = "-warn-swift3-objc-inference-minimal"
    ,   more       = "-warn-swift3-objc-inference-minimal"
    ,   all        = "-warn-swift3-objc-inference-complete"
    ,   everything = "-warn-swift3-objc-inference-complete"
    ,   error      = "-warnings-as-errors"
    }
    return maps[level]
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps = {
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
    local maps = {
        mmx   = "-mmmx"
    ,   sse   = "-msse"
    ,   sse2  = "-msse2"
    ,   sse3  = "-msse3"
    ,   ssse3 = "-mssse3"
    ,   avx   = "-mavx"
    ,   avx2  = "-mavx2"
    ,   neon  = "-mfpu=neon"
    }
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

-- make the compile arguments list
-- @see https://github.com/xmake-io/xmake/issues/3916
function compargv(self, sourcefile, objectfile, flags)
    local flags_new = {}
    for _, flag in ipairs(flags) do
        -- we need remove primary file in swift.build rule
        if flag ~= sourcefile then
            table.insert(flags_new, flag)
        end
    end
    return self:program(), table.join("-c", flags_new, "-o", objectfile, "-primary-file", sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)
    os.mkdir(path.directory(objectfile))
    os.runv(compargv(self, sourcefile, objectfile, flags))
end

