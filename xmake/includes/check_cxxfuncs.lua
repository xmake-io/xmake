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
-- @file        check_cxxfuncs.lua
--

-- check c++ funcs and add macro definition
--
-- the function syntax
--  - sigsetjmp
--  - sigsetjmp((void*)0, 0)
--  - sigsetjmp{sigsetjmp((void*)0, 0);}
--  - sigsetjmp{int a = 0; sigsetjmp((void*)a, a);}
--
-- e.g.
--
-- check_cxxfuncs("HAS_SETJMP", "setjmp", {includes = {"signal.h", "setjmp.h"}, links = {}})
-- check_cxxfuncs("HAS_SETJMP", {"setjmp", "sigsetjmp{sigsetjmp((void*)0, 0);}"})
--
function check_cxxfuncs(definition, funcs, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    option(optname)
        add_cxxfuncs(funcs)
        add_defines(definition)
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
    option_end()
    add_options(optname)
end

-- check c++ funcs and add macro definition to the configuration files
--
-- e.g.
--
-- configvar_check_cxxfuncs("HAS_SETJMP", "setjmp", {includes = {"signal.h", "setjmp.h"}, links = {}})
-- configvar_check_cxxfuncs("HAS_SETJMP", {"setjmp", "sigsetjmp{sigsetjmp((void*)0, 0);}"})
--
function configvar_check_cxxfuncs(definition, funcs, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    local defname, defval = unpack(definition:split('='))
    option(optname)
        add_cxxfuncs(funcs)
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
        if opt.cxflags then
            add_cxflags(opt.cxflags)
        end
        if opt.cxxflags then
            add_cxxflags(opt.cxxflags)
        end
        if opt.defines then
            add_defines(opt.defines)
        end
    option_end()
    add_options(optname)
end
