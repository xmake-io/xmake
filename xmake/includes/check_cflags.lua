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
-- @file        check_cflags.lua
--

-- check c flags and add macro definition
--
-- e.g.
--
-- check_cflags("HAS_SSE2", "-msse2")
-- check_cflags("HAS_SSE2", {"-msse2", "/arch:SSE2"})
--
function check_cflags(definition, flags, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    option(optname)
        add_defines(definition)
        on_check(function (option)
            import("core.tool.compiler")
            if compiler.has_flags("c", flags, opt) then
                option:enable(true)
            end
        end)
    option_end()
    add_options(optname)
end

-- check c flags and add macro definition to the configuration flags
--
-- e.g.
--
-- configvar_check_cflags("HAS_SSE2", "-msse2")
-- configvar_check_cflags("HAS_SSE2", {"-msse2", "/arch:SSE2"})
-- configvar_check_cflags("SSE=2", "-msse2")
--
function configvar_check_cflags(definition, flags, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    local defname, defval = unpack(definition:split('='))
    option(optname)
        set_configvar(defname, defval or 1)
        on_check(function (option)
            import("core.tool.compiler")
            if compiler.has_flags("c", flags, opt) then
                option:enable(true)
            end
        end)
    option_end()
    add_options(optname)
end
