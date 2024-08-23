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
-- @file        extract_xmz.lua
--

-- imports
import("core.base.option")
import("core.base.bytes")
import("core.compress.lz4")

-- extract files
function _extract_files(archivefile, outputdir, opt)
    local inputfile = io.open(archivefile, "rb")
    local filesize = inputfile:size()
    local readsize = 0
    while readsize < filesize do
        local data = inputfile:read(2)
        local size = bytes(data):u16be(1)
        local filepath
        if size > 0 then
            filepath = inputfile:read(size)
        end
        readsize = readsize + 2 + size
        data = inputfile:read(4)
        size = bytes(data):u32be(1)
        local filedata
        if size > 0 then
            filedata = inputfile:read(size)
        end
        readsize = readsize + 4 + size
        if filepath then
            vprint("extracting %s, %d bytes", filepath, filedata and #filedata or 0)
            if filedata then
                io.writefile(path.join(outputdir, filepath), filedata, {encoding = "binary"})
            else
                os.touch(filepath)
            end
        end
    end
    inputfile:close()
end

-- decompress file
function _decompress_file(archivefile, outputfile, opt)
    lz4.decompress_file(archivefile, outputfile)
end

-- extract file
--
-- @param archivefile   the archive file. e.g. *.tar.gz, *.zip, *.7z, *.tar.bz2, ..
-- @param outputdir     the output directory
-- @param options       the options, e.g.. {excludes = {"*/dir/*", "dir/*"}}
--
function main(archivefile, outputdir, opt)
    opt = opt or {}

    local archivefile_tmp = os.tmpfile({ramdisk = false})
    _decompress_file(archivefile, archivefile_tmp, opt)
    _extract_files(archivefile_tmp, outputdir, opt)
    os.tryrm(archivefile_tmp)
end
