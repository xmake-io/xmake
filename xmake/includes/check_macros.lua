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
-- @file        check_macros.lua
--

-- check macros and add macro definition
--
-- e.g.
--
--  check_macros("HAS_GCC", "__GNUC__")
--  check_macros("NO_GCC", "__GNUC__", {defined = false})
--  check_macros("HAS_CXX20", "__cplusplus >= 202002L", {languages = "c++20"})
--
function check_macros(definition, macros, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    local snippets = {}
    save_scope()
    option(optname)
        set_showmenu(false)
        for _, macro in ipairs(macros) do
            if macro:find(' ', 1, true) then
                table.insert(snippets, ([[
                #if %s
                #else
                #   #error %s is not satisfied!
                #endif
                ]]):format(macro, macro))
            else
                table.insert(snippets, ([[
                #if%s %s
                #else
                #   #error %s is not defined!
                #endif
                ]]):format(opt.defined ~= false and "def" or "ndef", macro, macro))
            end
        end
        if opt.languages and opt.languages:startswith("c++") then
            add_cxxsnippets(definition, table.concat(snippets, "\n"))
        else
            add_csnippets(definition, table.concat(snippets, "\n"))
        end
        add_defines(definition)
        if opt.languages then
            set_languages(opt.languages)
        end
        if opt.cflags then
            add_cflags(opt.cflags)
        end
        if opt.cxflags then
            add_cxflags(opt.cxflags)
        end
        if opt.cxxflags then
            add_cxxflags(opt.cxxflags)
        end
    option_end()
    restore_scope()
    add_options(optname)
end

-- check macros and add macro definition to the configuration files
--
-- e.g.
--  configvar_check_macros("HAS_GCC", "__GNUC__")
--  configvar_check_macros("NO_GCC", "__GNUC__", {defined = false})
--  configvar_check_macros("HAS_CXX20", "__cplusplus >= 202002L", {languages = "c++20"})
function configvar_check_macros(definition, macros, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    local defname, defval = table.unpack(definition:split('='))
    local snippets = {}
    save_scope()
    option(optname)
        set_showmenu(false)
        for _, macro in ipairs(macros) do
            if macro:find(' ', 1, true) then
                table.insert(snippets, ([[
                #if %s
                #else
                #   #error %s is not satisfied!
                #endif
                ]]):format(macro, macro))
            else
                table.insert(snippets, ([[
                #if%s %s
                #else
                #   #error %s is not defined!
                #endif
                ]]):format(opt.defined ~= false and "def" or "ndef", macro, macro))
            end
        end
        if opt.languages and opt.languages:startswith("c++") then
            add_cxxsnippets(definition, table.concat(snippets, "\n"))
        else
            add_csnippets(definition, table.concat(snippets, "\n"))
        end
        if opt.default == nil then
            set_configvar(defname, defval or 1, {quote = opt.quote})
        end
        if opt.languages then
            set_languages(opt.languages)
        end
        if opt.cflags then
            add_cflags(opt.cflags)
        end
        if opt.cxflags then
            add_cxflags(opt.cxflags)
        end
        if opt.cxxflags then
            add_cxxflags(opt.cxxflags)
        end
    option_end()
    restore_scope()
    if opt.default == nil then
        add_options(optname)
    else
        set_configvar(defname, has_config(optname) and (defval or 1) or opt.default, {quote = opt.quote})
    end
end
