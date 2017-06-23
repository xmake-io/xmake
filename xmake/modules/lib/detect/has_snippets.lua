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
-- @file        has_snippets.lua
--

-- imports
import("core.base.option")
import("core.tool.compiler")
import("core.language.language")

-- has this snippet?
function _has_snippet(snippet, opt)

    -- get the source kind
    local sourcekind = opt.sourcekind 
    if not sourcekind and opt.extension then
        sourcekind = language.extensions()[opt.extension] or "cc"
    end

    -- get the extension
    local extension = opt.extension
    if not extension and opt.sourcekind then
        extension = table.wrap(language.sourcekinds()[opt.sourcekind])[1] or ".c"
    end

    -- init cache and key
    local key     = opt.name
    local results = _g._RESULTS or {}
    
    -- get result from the cache first
    if key ~= nil then
        key = key .. sourcekind
        local result = results[key]
        if result ~= nil then
            return result
        end
    end

    -- make the source file
    local sourcefile = os.tmpfile() .. extension
    local objectfile = os.tmpfile() .. ".o"
    io.writefile(sourcefile, snippet)

    -- attempt to compile it
    local result = try { function () compiler.compile(sourcefile, objectfile, nil, opt.target, sourcekind); return true end }

    -- remove some files
    os.tryrm(sourcefile)
    os.tryrm(objectfile)

    -- trace
    if opt.name and (option.get("verbose") or opt.verbose) then
        cprint("checking for the %s %s ... %s", opt.kind or "snippet", opt.name, ifelse(result, "${green}ok", "${red}no"))
    end

    -- save result to cache
    if key ~= nil then
        results[key] = ifelse(result, result, false)
        _g._RESULTS = results
    end

    -- ok?
    return result
end

-- has the given snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, .e.g {kind = "snippet", name = "", verbose = false, target = [target|option], sourcekind = "[cc|cxx|mm|mxx|sc|dc|gc|rc]", extension = "[.c|.cpp|.m|.mm|.swift|.d|.go|.rs]"}
--
-- @return          true or false
--
-- @code
-- local ok = has_snippets("void test() {}") -- default: .c
-- local ok = has_snippets("void test() {}", {extension = ".cpp"}) 
-- local ok = has_snippets({"typedef wchar wchar_t;", "void test(){}"}, {sourcekind = "cxx"})
-- @endcode
--
function main(snippets, opt)

    -- init options
    opt = opt or {}

    -- has all snippets?
    for _, snippet in ipairs(snippets) do
        if not _has_snippet(snippet, opt) then
            return false
        end
    end

    -- ok
    return true
end
