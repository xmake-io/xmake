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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
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
    ,   vs2022 = '17.0'
    }

    -- make header
    filtersfile:print("<?xml version=\"1.0\" encoding=\"utf-8\"?>")
    filtersfile:enter("<Project ToolsVersion=\"%s\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">", vsinfo.filters_version or versions[vsinfo.vstudio_version])
end

-- make tailer
function _make_tailer(filtersfile, vsinfo)
    filtersfile:leave("</Project>")
end

-- strip dot directories, e.g. ..\..\.. => ..
-- @see https://github.com/xmake-io/xmake/issues/2039
function _strip_dotdirs(dir)
    local count
    dir, count = dir:gsub("%.%.[\\/]%.%.", "..")
    if count > 0 then
        dir = _strip_dotdirs(dir)
    end
    return dir
end

-- make filter
function _make_filter(filepath, target, vcxprojdir)
    local filter
    local is_plain = false
    local filegroups = target.filegroups
    if filegroups then
        -- @see https://github.com/xmake-io/xmake/issues/2282
        filepath = path.absolute(filepath)
        local scriptdir = target.scriptdir
        local filegroups_extraconf = target.filegroups_extraconf or {}
        for _, filegroup in ipairs(filegroups) do
            local extraconf = filegroups_extraconf[filegroup] or {}
            local rootdir = extraconf.rootdir
            assert(rootdir, "please set root directory, e.g. add_filegroups(%s, {rootdir = 'xxx'})", filegroup)
            for _, rootdir in ipairs(table.wrap(rootdir)) do
                if not path.is_absolute(rootdir) then
                    rootdir = path.absolute(rootdir, scriptdir)
                end
                local fileitem = path.relative(filepath, rootdir)
                local files = extraconf.files or "**"
                local mode = extraconf.mode
                for _, filepattern in ipairs(files) do
                    filepattern = path.pattern(path.absolute(path.join(rootdir, filepattern)))
                    if filepath:match(filepattern) then
                        if mode == "plain" then
                            filter = path.normalize(filegroup)
                            is_plain = true
                        else
                            -- file tree mode (default)
                            if filegroup ~= "" then
                                filter = path.normalize(path.join(filegroup, path.directory(fileitem)))
                            else
                                filter = path.normalize(path.directory(fileitem))
                            end
                        end
                        goto found_filter
                    end
                end
                -- stop once a rootdir matches
                if filter then
                    goto found_filter
                end
            end
            ::found_filter::
        end
    end
    if not filter and not is_plain then
        -- use the default filter rule
        filter = path.relative(path.absolute(path.directory(filepath)), target.scriptdir or vcxprojdir)
        -- @see https://github.com/xmake-io/xmake/issues/2039
        if filter then
            filter = _strip_dotdirs(filter)
        end
    end
    if filter and filter == '.' then
        filter = nil
    end
    return filter
end

-- make filters
function _make_filters(filtersfile, vsinfo, target, vcxprojdir)

    -- add filters
    filtersfile:enter("<ItemGroup>")
        local exists = {}
        for _, filepath in pairs(table.join(target.sourcefiles, target.headerfiles or {}, target.extrafiles)) do
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
                local nodename
                local ext = path.extension(sourcefile)
                if ext == "asm" then nodename = "CustomBuild"
                elseif ext == "cu" then nodename = "CudaCompile"
                else nodename = "ClCompile"
                end
                filtersfile:enter("<%s Include=\"%s\">", nodename, path.relative(path.absolute(sourcefile), vcxprojdir))
                filtersfile:print("<Filter>%s</Filter>", filter)
                filtersfile:leave("</%s>", nodename)
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

-- make includes
function _make_includes(filtersfile, vsinfo, target, vcxprojdir)
    filtersfile:enter("<ItemGroup>")
        for _, includefile in ipairs(table.join(target.headerfiles or {}, target.extrafiles)) do
            local filter = _make_filter(includefile, target, vcxprojdir)
            if filter then
                filtersfile:enter("<ClInclude Include=\"%s\">", path.relative(path.absolute(includefile), vcxprojdir))
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

    -- make includes
    _make_includes(filtersfile, vsinfo, target, vcxprojdir)

    -- make tailer
    _make_tailer(filtersfile, vsinfo)

    -- exit solution file
    filtersfile:close()
end
