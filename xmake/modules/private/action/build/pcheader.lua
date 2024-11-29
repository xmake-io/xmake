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
        local sourcekind = language.langkinds()[langkind] or "cxx"
        if target:has_tool(sourcekind, "cl", "clang_cl", "gcc", "gxx") then
            local headerfile = target:autogenfile(pcheaderfile)
            local gcc = false
            if target:has_tool(sourcekind, "gcc", "gxx") then
                local pcoutputfile = target:pcoutputfile(langkind)
                headerfile = path.join(path.directory(pcoutputfile), path.filename(headerfile))
                gcc = true
            end
            -- fix `#pragma once` for msvc
            -- https://github.com/xmake-io/xmake/issues/2667
            -- https://github.com/xmake-io/xmake/issues/5858
            if not os.isfile(headerfile) then
                io.writefile(headerfile, ([[
#pragma system_header
#ifdef __cplusplus
#include "%s"
#endif // __cplusplus
                ]]):format(path.absolute(pcheaderfile):gsub("\\", "/")))
            end
            -- we need only to add a header wrapper in .gch directory
            -- @see https://github.com/xmake-io/xmake/issues/5858#issuecomment-2506918167
            if not gcc then
                target:pcheaderfile_set(langkind, headerfile)
            end
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
