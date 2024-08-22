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
-- @file        archive_xmz.lua
--

-- imports
import("core.base.option")
import("core.base.bytes")
import("core.compress.lz4")

-- archive files
function _archive_files(archivefile, inputfiles, opt)
    local curdir = opt.curdir
    local outputfile = io.open(archivefile, "wb")
    for _, inputfile in ipairs(inputfiles) do
        local filepath = inputfile
        if curdir then
            filepath = path.relative(filepath, curdir)
        end
        outputfile:write(bytes(2):u16be_set(1, #filepath))
        outputfile:write(filepath)
        local data = io.readfile(inputfile, {encoding = "binary"})
        vprint("archiving %s, %d bytes", inputfile, data and #data or 0)
        outputfile:write(bytes(4):u32be_set(1, #data))
        outputfile:write(data)
    end
    outputfile:close()
end

-- compress file
function _compress_file(archivefile, outputfile, opt)
    lz4.compress_file(archivefile, outputfile)
end

-- archive file
--
-- @param archivefile   the archive file. e.g. *.tar.gz, *.zip, *.7z, *.tar.bz2, ..
-- @param inputfiles    the input file or directory or list
-- @param options       the options, e.g.. {curdir = "/tmp", recurse = true, compress = "fastest|faster|default|better|best", excludes = {"*/dir/*", "dir/*"}}
--
function main(archivefile, inputfiles, opt)
    opt = opt or {}
    local files = {}
    for _, inputfile in ipairs(inputfiles) do
        if os.isdir(inputfile) then
            table.join2(files, os.files(path.join(inputfile, opt.recurse and "**" or "*")))
        elseif os.isfile(inputfile) then
            table.insert(files, inputfile)
        end
    end
    inputfiles = files

    local archivefile_tmp = os.tmpfile({ramdisk = false})
    _archive_files(archivefile_tmp, inputfiles, opt)
    _compress_file(archivefile_tmp, archivefile, opt)
    os.tryrm(archivefile_tmp)
end
