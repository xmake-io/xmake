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
-- @file        check_cflags.lua
--

-- check c flags and add macro definition
--
-- e.g.
--
-- check_cflags("HAS_SSE2", "-msse2")
-- check_cflags("HAS_SSE2", {"-msse", "-msse2"})
--
function check_cflags(definition, flags, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    save_scope()
    option(optname)
        set_showmenu(false)
        add_defines(definition)
        on_check(function (option)
            import("core.tool.compiler")
            if compiler.has_flags("c", flags, opt) then
                option:enable(true)
            end
        end)
    option_end()
    restore_scope()
    add_options(optname)
end

-- check c flags and add macro definition to the configuration flags
--
-- e.g.
--
-- configvar_check_cflags("HAS_SSE2", "-msse2")
-- configvar_check_cflags("HAS_SSE2", {"-msse", "-msse2"})
-- configvar_check_cflags("HAS_SSE2", "-msse2", {default = 0})
-- configvar_check_cflags("SSE_STR=2", "-msse2")
-- configvar_check_cflags("SSE=2", "-msse2", {quote = false})
--
function configvar_check_cflags(definition, flags, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    local defname, defval = table.unpack(definition:split('='))
    save_scope()
    option(optname)
        set_showmenu(false)
        if opt.default == nil then
            set_configvar(defname, defval or 1, {quote = opt.quote})
        end
        on_check(function (option)
            import("core.tool.compiler")
            if compiler.has_flags("c", flags, opt) then
                option:enable(true)
            end
        end)
    option_end()
    restore_scope()
    if opt.default == nil then
        add_options(optname)
    else
        set_configvar(defname, has_config(optname) and (defval or 1) or opt.default, {quote = opt.quote})
    end
end
