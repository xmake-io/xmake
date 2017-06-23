--!The Make-like Build Utility based on Lua
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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        has_ctypes.lua
--

-- imports
import("lib.detect.has_snippets")

-- has this ctype?
function _has_ctype(ctype, opt)

    -- init name and type
    opt.name       = ctype
    opt.kind       = "c type"
    opt.sourcekind = "cc"
    opt.extension  = ".c"

    -- make snippet
    local snippet = ""
    for _, include in ipairs(opt.includes) do
        snippet = format("%s\n#include <%s>", snippet, include)
    end
    snippet = format("%s\n\ntypedef %s __type_xxx;", snippet, ctype)

    -- ok?
    return has_snippets(snippet, opt)
end

-- has the given ctypes?
--
-- @param ctypes    the ctypes
-- @param opt       the argument options, .e.g {verbose = false, target = [target|option], includes = {"stdio.h", "stdlib.h"}}
--
-- @return          true or false
--
-- @code
-- local ok = has_ctypes("wchar_t") 
-- @endcode
--
function main(ctypes, opt)

    -- init options
    opt = opt or {}

    -- has all ctypes?
    for _, ctype in ipairs(ctypes) do
        if not _has_ctype(ctype, opt) then
            return false
        end
    end

    -- ok
    return true
end
