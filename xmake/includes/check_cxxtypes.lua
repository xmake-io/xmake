--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check_cxxtypes.lua
--

-- check c++ types and add macro definition 
--
-- e.g.
--
-- check_cxxtypes("HAS_WCHAR", "wchar_t")
-- check_cxxtypes("HAS_WCHAR_AND_FLOAT", {"wchar_t", "float"})
--
function check_cxxtypes(definition, types, opt)
    opt = opt or {}
    option(definition)
        add_cxxtypes(types)
        add_defines(definition)
        if opt.languages then
            set_languages(opt.languages)
        end
        if opt.cxflags then
            add_cxflags(opt.cxflags)
        end
        if opt.cxxflags then
            add_cxxflags(opt.cxxflags)
        end
    option_end()
    add_options(definition)
end

-- check c++ types and add macro definition to the configuration types 
--
-- e.g.
--
-- configvar_check_cxxtypes("HAS_WCHAR", "wchar_t")
-- configvar_check_cxxtypes("HAS_WCHAR_AND_FLOAT", {"wchar_t", "float"})
--
function configvar_check_cxxtypes(definition, types, opt)
    opt = opt or {}
    option(definition)
        add_cxxtypes(types)
        set_configvar(definition, 1)
        if opt.languages then
            set_languages(opt.languages)
        end
        if opt.cxflags then
            add_cxflags(opt.cxflags)
        end
        if opt.cxxflags then
            add_cxxflags(opt.cxxflags)
        end
    option_end()
    add_options(definition)
end
