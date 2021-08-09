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
-- @file        check_csnippets.lua
--

-- check c snippets and add macro definition
--
-- e.g.
--
-- check_csnippets("HAS_STATIC_ASSERT", "_Static_assert(1, \"\");", {includes = "stdio.h"})
-- check_csnippets("HAS_LONG_8", "return (sizeof(long) == 8)? 0 : -1;", {tryrun = true})
-- check_csnippets("PTR_SIZE", 'printf("%d", sizeof(void*)); return 0;', {output = true, number = true})
--
function check_csnippets(definition, snippets, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    option(optname)
        add_csnippets(definition, snippets, {tryrun = opt.tryrun, output = opt.output})
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
        if opt.cflags then
            add_cflags(opt.cflags)
        end
        if opt.cxflags then
            add_cxflags(opt.cxflags)
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
                    else
                        option:add("defines", definition .. "=\"" .. option:value() .. "\"")
                    end
                end
            end)
        end
    option_end()
    add_options(optname)
end

-- check c snippets and add macro definition to the configuration snippets
--
-- e.g.
--
-- configvar_check_csnippets("HAS_STATIC_ASSERT", "_Static_assert(1, \"\");", {includes = "stdio.h"})
-- configvar_check_csnippets("HAS_LONG_8", "return (sizeof(long) == 8)? 0 : -1;", {tryrun = true})
-- configvar_check_csnippets("PTR_SIZE", 'printf("%d", sizeof(void*)); return 0;', {output = true, number = true})
--
function configvar_check_csnippets(definition, snippets, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    local defname, defval = unpack(definition:split('='))
    option(optname)
        add_csnippets(definition, snippets, {tryrun = opt.tryrun, output = opt.output})
        set_configvar(defname, defval or 1)
        if opt.links then
            add_links(opt.links)
        end
        if opt.includes then
            add_cincludes(opt.includes)
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
        if opt.defines then
            add_defines(opt.defines)
        end
        if opt.warnings then
            set_warnings(opt.warnings)
        end
        if opt.output then
            after_check(function (option)
                if option:value() then
                    option:set("configvar", defname, opt.number and tonumber(option:value()) or option:value())
                end
            end)
        end
    option_end()
    add_options(optname)
end
