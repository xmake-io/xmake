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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        check_cfuncs.lua
--

-- check c funcs and add macro definition
--
-- the function syntax
--  - sigsetjmp
--  - sigsetjmp((void*)0, 0)
--  - sigsetjmp{sigsetjmp((void*)0, 0);}
--  - sigsetjmp{int a = 0; sigsetjmp((void*)a, a);}
--
-- e.g.
--
-- check_cfuncs("HAS_SETJMP", "setjmp", {includes = {"signal.h", "setjmp.h"}, links = {}})
-- check_cfuncs("HAS_SETJMP", {"setjmp", "sigsetjmp{sigsetjmp((void*)0, 0);}"})
--
function check_cfuncs(definition, funcs, opt)
    opt = opt or {}
    local optname = opt.name or ("__" .. definition)
    interp_save_scope()
    option(optname)
        set_showmenu(false)
        add_cfuncs(funcs)
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
    option_end()
    interp_restore_scope()
    add_options(optname)
end

-- check c funcs and add macro definition to the configuration files
--
-- e.g.
--
-- configvar_check_cfuncs("HAS_SETJMP", "setjmp", {includes = {"signal.h", "setjmp.h"}, links = {}})
-- configvar_check_cfuncs("HAS_SETJMP", {"setjmp", "sigsetjmp{sigsetjmp((void*)0, 0);}"})
-- configvar_check_cfuncs("HAS_SETJMP", "setjmp", {includes = {"setjmp.h"}, default = 0})
-- configvar_check_cfuncs("CUSTOM_SETJMP=setjmp", "setjmp", {includes = {"setjmp.h"}, default = "", quote = false})
--
function configvar_check_cfuncs(definition, funcs, opt)
    opt = opt or {}
    local optname = opt.name or ("__" .. definition)
    local defname, defval = table.unpack(definition:split('='))
    interp_save_scope()
    option(optname)
        set_showmenu(false)
        add_cfuncs(funcs)
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
    option_end()
    interp_restore_scope()
    if opt.default == nil then
        add_options(optname)
    else
        set_configvar(defname, has_config(optname) and (defval or 1) or opt.default, {quote = opt.quote})
    end
end
