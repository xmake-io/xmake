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
-- @file        match_copyfiles.lua
--

-- load modules
local table = require("base/table")
local utils = require("base/utils")
local path  = require("base/path")
local os    = require("base/os")

-- match the copyfiles for instance
-- e.g.
--
-- add_headerfiles
-- add_configfiles
-- add_installfiles
-- add_extrafiles
function match_copyfiles(instance, filetype, outputdir, pathfilter)

    -- no copied files?
    local copyfiles = instance:get(filetype)
    if not copyfiles then return end

    -- get the extra information
    local extrainfo = table.wrap(instance:extraconf(filetype))

    -- get the source paths and destinate paths
    local srcfiles = {}
    local dstfiles = {}
    local fileinfos = {}
    for _, copyfile in ipairs(table.wrap(copyfiles)) do

        -- get the root directory
        local rootdir, count = copyfile:gsub("|.*$", ""):gsub("%(.*%)$", "")
        if count == 0 then
            rootdir = nil
        end
        if rootdir and rootdir:trim() == "" then
            rootdir = "."
        end

        -- remove '(' and ')'
        local srcpaths = copyfile:gsub("[%(%)]", "")
        if srcpaths then

            -- get the source paths
            srcpaths = os.match(srcpaths)
            if srcpaths and #srcpaths > 0 then

                -- add the source copied files
                table.join2(srcfiles, srcpaths)

                -- the copied directory exists?
                if outputdir then

                    -- get the file info
                    local fileinfo = extrainfo[copyfile] or {}

                    -- get the prefix directory
                    local prefixdir = fileinfo.prefixdir
                    if fileinfo.rootdir then
                        rootdir = fileinfo.rootdir
                    end

                    -- add the destinate copied files
                    for _, srcpath in ipairs(srcpaths) do

                        -- get the destinate directory
                        local dstdir = outputdir
                        if prefixdir then
                            dstdir = path.join(dstdir, prefixdir)
                        end

                        -- the destinate file
                        local dstfile = nil
                        if rootdir then
                            dstfile = path.absolute(path.relative(srcpath, rootdir), dstdir)
                        else
                            dstfile = path.join(dstdir, path.filename(srcpath))
                        end
                        assert(dstfile)

                        -- modify filename
                        if fileinfo.filename then
                            dstfile = path.join(path.directory(dstfile), fileinfo.filename)
                        end

                        -- filter the destinate file path
                        if pathfilter then
                            dstfile = pathfilter(dstfile, fileinfo)
                        end

                        -- add it
                        table.insert(dstfiles, dstfile)
                        table.insert(fileinfos, fileinfo)
                    end
                end
            end
        end
    end
    return srcfiles, dstfiles, fileinfos
end

return match_copyfiles
