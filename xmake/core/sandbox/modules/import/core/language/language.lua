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
-- @file        language.lua
--

-- define module
local sandbox_core_language = sandbox_core_language or {}

-- load modules
local language  = require("language/language")
local raise     = require("sandbox/modules/raise")

-- get the source extensions of all languages
function sandbox_core_language.extensions()

    -- get it
    return language.extensions()
end

-- get the target kinds of all languages
function sandbox_core_language.targetkinds()

    -- get it
    return language.targetkinds()
end

-- get the source kinds of all languages
function sandbox_core_language.sourcekinds()

    -- get it
    return language.sourcekinds()
end

-- get the source flags of all languages
function sandbox_core_language.sourceflags()

    -- get it
    return language.sourceflags()
end

-- get the linker kinds of all languages
function sandbox_core_language.linkerkinds()

    -- get it
    return language.linkerkinds()
end

-- load the language from the given name (c++, objc++, swift, golang, asm, ...)
function sandbox_core_language.load(name)

    -- load it
    local instance, errors = language.load(name)
    if not instance then
        raise(errors)
    end

    -- ok
    return instance
end

-- load the language from the given source kind: cc, cxx, mm, mxx, sc, go, as ..
function sandbox_core_language.load_sk(sourcekind)

    -- load it
    local instance, errors = language.load_sk(sourcekind)
    if not instance then
        raise(errors)
    end

    -- ok
    return instance
end

-- load the language from the given source extension: .c, .cpp, .m, .mm, .swift, .go, .s ..
function sandbox_core_language.load_ex(extension)

    -- load it
    local instance, errors = language.load_ex(extension)
    if not instance then
        raise(errors)
    end

    -- ok
    return instance
end

-- get source kind of the source file name
function sandbox_core_language.sourcekind_of(sourcefile)

    -- get it
    local sourcekind, errors = language.sourcekind_of(sourcefile)
    if not sourcekind then
        raise(errors)
    end

    -- ok
    return sourcekind
end

-- get linker info (kind and flag) of the source kinds
function sandbox_core_language.linkerinfo_of(targetkind, sourcekinds)

    -- get it
    local linkerinfo, errors = language.linkerinfo_of(targetkind, sourcekinds)
    if not linkerinfo then
        raise(errors)
    end

    -- ok
    return linkerinfo
end

-- return module
return sandbox_core_language
