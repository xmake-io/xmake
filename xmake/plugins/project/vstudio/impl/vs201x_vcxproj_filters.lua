--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      EnoroF, ruki
-- @file        vs201x_vcxproj_filters.lua
--

-- imports
import("core.tool.compiler")
import("vsfile")

-- make header
function _make_header(filtersfile, vsinfo, target)
    
    -- the versions
    local versions = 
    {
        vs2010 = '10.0'
    ,   vs2012 = '11.0'
    ,   vs2013 = '12.0'
    ,   vs2015 = '14.0'
    ,   vs2017 = '15.0'
    }

    -- make header
    filtersfile:print("<?xml version=\"1.0\" encoding=\"utf-8\"?>")
    filtersfile:enter("<Project ToolsVersion=\"%s\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">", vsinfo.filters_version or versions[vsinfo.vstudio_version])
end

-- make tailer
function _make_tailer(filtersfile, vsinfo, target)
    filtersfile:leave("</Project>")
end

-- make filter
function _make_filter(filepath, target, vcxprojdir)

    -- make filter
    local filter = path.relative(path.absolute(path.directory(filepath)), target:scriptdir() or vcxprojdir)

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
        for _, filepath in pairs(table.join(target:sourcefiles(), (target:headerfiles()))) do
            local filter = _make_filter(filepath, target, vcxprojdir)
            while filter and filter ~= '.' do
                if not exists[filter] then
                    filtersfile:enter("<Filter Include=\"%s\">", filter)
                    filtersfile:print("<UniqueIdentifier>{%s}</UniqueIdentifier>", os.uuid(filter))
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
        for _, sourcefile in ipairs(target:sourcefiles()) do
            local filter = _make_filter(sourcefile, target, vcxprojdir)
            if filter then
                filtersfile:enter("<ClCompile Include=\"%s\">", path.relative(path.absolute(sourcefile), vcxprojdir))
                filtersfile:print("<Filter>%s</Filter>", filter)
                filtersfile:leave("</ClCompile>")
            end
        end
    filtersfile:leave("</ItemGroup>")
end

-- make headers
function _make_headers(filtersfile, vsinfo, target, vcxprojdir)
    
    -- and headers
    filtersfile:enter("<ItemGroup>")
        for _, headerfile in ipairs(target:headerfiles()) do
            local filter = _make_filter(headerfile, target, vcxprojdir)
            if filter then
                filtersfile:enter("<ClInclude Include=\"%s\">", path.relative(path.absolute(headerfile), vcxprojdir))
                filtersfile:print("<Filter>%s</Filter>", _make_filter(headerfile, target, vcxprojdir))
                filtersfile:leave("</ClInclude>")
            end
        end
    filtersfile:leave("</ItemGroup>")
end

-- main filters
function make(vsinfo, target)

    -- the target name
    local targetname = target:name()

    -- the vcxproj directory
    local vcxprojdir = path.join(vsinfo.solution_dir, targetname)

    -- open vcxproj.filters file
    local filtersfile = vsfile.open(path.join(vcxprojdir, targetname .. ".vcxproj.filters"), "w")

    -- init indent character
    vsfile.indentchar('  ')

    -- make header
    _make_header(filtersfile, vsinfo, target)

    -- make filters
    _make_filters(filtersfile, vsinfo, target, vcxprojdir)

    -- make sources
    _make_sources(filtersfile, vsinfo, target, vcxprojdir)

    -- make headers
    _make_headers(filtersfile, vsinfo, target, vcxprojdir)

    -- make tailer
    _make_tailer(filtersfile, vsinfo, target)

    -- exit solution file
    filtersfile:close()
end
