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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      EnoroF, ruki
-- @file        vs201x_vcxproj_filters.lua
--

-- imports
import("core.tool.compiler")
import("vsfile")

-- make header
function _make_header(filtersfile, vsinfo)

    -- the versions
    local versions =
    {
        vs2010 = '10.0'
    ,   vs2012 = '11.0'
    ,   vs2013 = '12.0'
    ,   vs2015 = '14.0'
    ,   vs2017 = '15.0'
    ,   vs2019 = '16.0'
    }

    -- make header
    filtersfile:print("<?xml version=\"1.0\" encoding=\"utf-8\"?>")
    filtersfile:enter("<Project ToolsVersion=\"%s\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">", vsinfo.filters_version or versions[vsinfo.vstudio_version])
end

-- make tailer
function _make_tailer(filtersfile, vsinfo)
    filtersfile:leave("</Project>")
end

-- make filter
function _make_filter(filepath, target, vcxprojdir)

    -- make filter
    local filter = path.relative(path.absolute(path.directory(filepath)), target.scriptdir or vcxprojdir)

    -- is '.'? no filter
    if filter and filter == '.' then
        filter = nil
    end

    -- ok?
    return filter
end

-- make filters
function _make_filters(filtersfile, vsinfo, target, vcxprojdir)

    -- add filters
    filtersfile:enter("<ItemGroup>")
        local exists = {}
        for _, filepath in pairs(table.join(target.sourcefiles, target.headerfiles)) do
            local filter = _make_filter(filepath, target, vcxprojdir)
            while filter and filter ~= '.' do
                if not exists[filter] then
                    filtersfile:enter("<Filter Include=\"%s\">", filter)
                    filtersfile:print("<UniqueIdentifier>{%s}</UniqueIdentifier>", hash.uuid4(filter))
                    filtersfile:leave("</Filter>")
                    exists[filter] = true
                end
                filter = path.directory(filter)
            end
        end
    filtersfile:leave("</ItemGroup>")
end

-- make sources
function _make_sources(filtersfile, vsinfo, target, vcxprojdir)

    -- and sources
    filtersfile:enter("<ItemGroup>")
        for _, sourcefile in ipairs(target.sourcefiles) do
            local filter = _make_filter(sourcefile, target, vcxprojdir)
            if filter then
                local as = sourcefile:endswith(".asm")
                filtersfile:enter("<%s Include=\"%s\">", (as and "CustomBuild" or "ClCompile"), path.relative(path.absolute(sourcefile), vcxprojdir))
                filtersfile:print("<Filter>%s</Filter>", filter)
                filtersfile:leave("</%s>", (as and "CustomBuild" or "ClCompile"))
            end
            local pcheader = target.pcxxheader or target.pcheader
            if pcheader then
                local filter = _make_filter(pcheader, target, vcxprojdir)
                if filter then
                    filtersfile:enter("<ClCompile Include=\"%s\">", path.relative(path.absolute(pcheader), vcxprojdir))
                    filtersfile:print("<Filter>%s</Filter>", filter)
                    filtersfile:leave("</ClCompile>")
                end
            end
        end
    filtersfile:leave("</ItemGroup>")
end

-- make headers
function _make_headers(filtersfile, vsinfo, target, vcxprojdir)

    -- and headers
    filtersfile:enter("<ItemGroup>")
        for _, headerfile in ipairs(target.headerfiles) do
            local filter = _make_filter(headerfile, target, vcxprojdir)
            if filter then
                filtersfile:enter("<ClInclude Include=\"%s\">", path.relative(path.absolute(headerfile), vcxprojdir))
                filtersfile:print("<Filter>%s</Filter>", filter)
                filtersfile:leave("</ClInclude>")
            end
        end
    filtersfile:leave("</ItemGroup>")
end

-- main filters
function make(vsinfo, target)

    -- the target name
    local targetname = target.name

    -- the vcxproj directory
    local vcxprojdir = path.join(vsinfo.solution_dir, targetname)

    -- open vcxproj.filters file
    local filterspath = path.join(vcxprojdir, targetname .. ".vcxproj.filters")
    local filtersfile = vsfile.open(filterspath, "w")

    -- init indent character
    vsfile.indentchar('  ')

    -- make header
    _make_header(filtersfile, vsinfo)

    -- make filters
    _make_filters(filtersfile, vsinfo, target, vcxprojdir)

    -- make sources
    _make_sources(filtersfile, vsinfo, target, vcxprojdir)

    -- make headers
    _make_headers(filtersfile, vsinfo, target, vcxprojdir)

    -- make tailer
    _make_tailer(filtersfile, vsinfo)

    -- exit solution file
    filtersfile:close()
end
