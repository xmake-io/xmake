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
-- @file        archive.lua
--

-- imports
import("core.base.option")
import("utils.archive")
import("batchcmds")

-- pack archive package
function _pack_archive(package)

    -- archive source files
    if package:from_source() then
        local srcfiles, dstfiles = package:sourcefiles()
        for idx, srcfile in ipairs(srcfiles) do
            os.vcp(srcfile, dstfiles[idx])
        end
        for _, component in table.orderpairs(package:components()) do
            if component:get("default") ~= false then
                local srcfiles, dstfiles = component:sourcefiles()
                for idx, srcfile in ipairs(srcfiles) do
                    os.vcp(srcfile, dstfiles[idx])
                end
            end
        end
    else
        -- archive binary files
        batchcmds.get_installcmds(package):runcmds()
        for _, component in table.orderpairs(package:components()) do
            if component:get("default") ~= false then
                batchcmds.get_installcmds(component):runcmds()
            end
        end
    end

    -- archive install files
    local rootdir = package:from_source() and package:source_rootdir() or package:install_rootdir()
    local oldir = os.cd(rootdir)
    local archivefiles = os.files("**")
    os.cd(oldir)
    os.tryrm(package:outputfile())
    archive.archive(path.absolute(package:outputfile()), archivefiles, {curdir = rootdir, compress = "best"})
end

function main(package)
    cprint("packing %s .. ", package:outputfile())
    _pack_archive(package)
end

