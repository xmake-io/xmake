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
-- @file        check_cxxsnippets.lua
--

-- check c++ snippets and add macro definition
--
-- e.g.
--
-- check_cxxsnippets("HAS_STATIC_ASSERT", "static_assert(1, \"\");")
-- check_csnippets("HAS_LONG_8", "return (sizeof(long) == 8)? 0 : -1;", {tryrun = true})
-- check_csnippets("PTR_SIZE", 'printf("%d", sizeof(void*)); return 0;', {output = true, number = true})
--
function check_cxxsnippets(definition, snippets, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    save_scope()
    option(optname)
        set_showmenu(false)
        add_cxxsnippets(definition, snippets, {tryrun = opt.tryrun, output = opt.output})
        if not opt.output then
            add_defines(definition)
        end
        if opt.links then
            add_links(opt.links)
        end
        if opt.includes then
            add_cincludes(opt.includes)
        end
        if opt.languages then
            set_languages(opt.languages)
        end
        if opt.cxflags then
            add_cxflags(opt.cxflags)
        end
        if opt.cxxflags then
            add_cxxflags(opt.cxxflags)
        end
        if opt.defines then
            add_defines(opt.defines)
        end
        if opt.warnings then
            set_warnings(opt.warnings)
        end
        if opt.output then
            after_check(function (option)
                if option:value() then
                    if opt.number then
                        option:add("defines", definition .. "=" .. tonumber(option:value()))
                    elseif opt.quote == false then
                        option:add("defines", definition .. "=" .. option:value())
                    else
                        option:add("defines", definition .. "=\"" .. option:value() .. "\"")
                    end
                end
            end)
        end
    option_end()
    restore_scope()
    add_options(optname)
end

-- check c++ snippets and add macro definition to the configuration snippets
--
-- e.g.
--
-- configvar_check_cxxsnippets("HAS_STATIC_ASSERT", "static_assert(1, \"\");")
-- configvar_check_cxxsnippets("HAS_LONG_8", "return (sizeof(long) == 8)? 0 : -1;", {tryrun = true})
-- configvar_check_cxxsnippets("HAS_LONG_8", "return (sizeof(long) == 8)? 0 : -1;", {tryrun = true, default = 0})
-- configvar_check_cxxsnippets("LONG_SIZE=8", "return (sizeof(long) == 8)? 0 : -1;", {tryrun = true, quote = false})
-- configvar_check_cxxsnippets("PTR_SIZE", 'printf("%d", sizeof(void*)); return 0;', {output = true, number = true})
--
function configvar_check_cxxsnippets(definition, snippets, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    local defname, defval = table.unpack(definition:split('='))
    save_scope()
    option(optname)
        set_showmenu(false)
        add_cxxsnippets(definition, snippets, {tryrun = opt.tryrun, output = opt.output})
        if opt.default == nil then
            set_configvar(defname, defval or 1, {quote = opt.quote})
        end
        if opt.links then
            add_links(opt.links)
        end
        if opt.includes then
            add_cincludes(opt.includes)
        end
        if opt.languages then
            set_languages(opt.languages)
        end
        if opt.cxflags then
            add_cxflags(opt.cxflags)
        end
        if opt.cxxflags then
            add_cxxflags(opt.cxxflags)
        end
        if opt.defines then
            add_defines(opt.defines)
        end
        if opt.warnings then
            set_warnings(opt.warnings)
        end
        if opt.output then
            after_check(function (option)
                if option:value() then
                    option:set("configvar", defname, opt.number and tonumber(option:value()) or option:value(), {quote = opt.quote})
                end
            end)
        end
    option_end()
    restore_scope()
    if opt.default == nil then
        add_options(optname)
    else
        set_configvar(defname, has_config(optname) and (defval or 1) or opt.default, {quote = opt.quote})
    end
end
