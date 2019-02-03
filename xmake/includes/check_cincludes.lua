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
-- @file        check_cincludes.lua
--

-- check include c files and add macro definition 
--
-- e.g.
--
-- check_cincludes("HAS_STRING_H", "string.h")
-- check_cincludes("HAS_STRING_AND_STDIO_H", {"string.h", "stdio.h"})
--
function check_cincludes(definition, includes)
    option(definition)
        add_cincludes(includes)
        add_defines(definition)
    option_end()
    add_options(definition)
end

-- check include c files and add macro definition to the configuration files 
--
-- e.g.
--
-- configvar_check_cincludes("HAS_STRING_H", "string.h")
-- configvar_check_cincludes("HAS_STRING_AND_STDIO_H", {"string.h", "stdio.h"})
--
function configvar_check_cincludes(definition, includes)
    option(definition)
        add_cincludes(includes)
        set_configvar(definition, 1)
    option_end()
    add_options(definition)
end
