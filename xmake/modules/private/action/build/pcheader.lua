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
-- @file        pcheader.lua
--

-- imports
import("core.language.language")
import("object")

function config(target, langkind, opt)
    local pcheaderfile = target:pcheaderfile(langkind)
    if pcheaderfile then
        local headerfile = target:autogenfile(pcheaderfile)
        if target:is_plat("windows") and
            target:has_tool(langkind == "cxx" and "cxx" or "cc", "cl", "clang_cl") then
             -- fix `#pragma once` for msvc
             -- https://github.com/xmake-io/xmake/issues/2667
             if not os.isfile(headerfile) then
                io.writefile(headerfile, ([[
#pragma system_header
#ifdef __cplusplus
#include "%s"
#endif // __cplusplus
                ]]):format(path.absolute(pcheaderfile):gsub("\\", "/")))
            end
            target:pcheaderfile_set(langkind, headerfile)
        end
    end
end

-- add batch jobs to build the precompiled header file
function build(target, langkind, opt)
    local pcheaderfile = target:pcheaderfile(langkind)
    if pcheaderfile then
        local sourcefile = pcheaderfile
        local objectfile = target:pcoutputfile(langkind)
        local dependfile = target:dependfile(objectfile)
        local sourcekind = language.langkinds()[langkind]
        local sourcebatch = {sourcekind = sourcekind, sourcefiles = {sourcefile}, objectfiles = {objectfile}, dependfiles = {dependfile}}
        object.build(target, sourcebatch, opt)
    end
end
