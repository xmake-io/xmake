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
-- @file        check_cxxincludes.lua
--

-- check include c++ files and add macro definition
--
-- e.g.
--
-- check_cxxincludes("HAS_STRING_H", "string.h")
-- check_cxxincludes("HAS_STRING_AND_STDIO_H", {"string.h", "stdio.h"})
--
function check_cxxincludes(definition, includes, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    option(optname)
        add_cxxincludes(includes)
        add_defines(definition)
    option_end()
    add_options(optname)
end

-- check include c++ files and add macro definition to the configuration files
--
-- e.g.
--
-- configvar_check_cxxincludes("HAS_STRING_H", "string.h")
-- configvar_check_cxxincludes("HAS_STRING_AND_STDIO_H", {"string.h", "stdio.h"})
--
function configvar_check_cxxincludes(definition, includes, opt)
    opt = opt or {}
    local optname = "__" .. (opt.name or definition)
    local defname, defval = unpack(definition:split('='))
    option(optname)
        add_cxxincludes(includes)
        set_configvar(defname, defval or 1)
    option_end()
    add_options(optname)
end
