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
-- @file        check_features.lua
--

-- check features and add macro definition
--
-- e.g.
--
-- check_features("HAS_CONSTEXPR", "cxx_constexpr")
-- check_features("HAS_CONSEXPR_AND_STATIC_ASSERT", {"cxx_constexpr", "c_static_assert"}, {cxflags = "", languages = "c++11"})
--
function check_features(definition, features, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    save_scope()
    option(optname)
        set_showmenu(false)
        add_features(features)
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

-- check features and add macro definition to the configuration files
--
-- e.g.
--
-- configvar_check_features("HAS_CONSTEXPR", "cxx_constexpr")
-- configvar_check_features("HAS_CONSTEXPR", "cxx_constexpr", {default = 0})
-- configvar_check_features("HAS_CONSEXPR_AND_STATIC_ASSERT", {"cxx_constexpr", "c_static_assert"}, {languages = "c++11"})
--
function configvar_check_features(definition, features, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    local defname, defval = table.unpack(definition:split('='))
    save_scope()
    option(optname)
        set_showmenu(false)
        add_features(features)
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
