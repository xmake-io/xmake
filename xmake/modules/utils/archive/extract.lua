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
-- @file        extract.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_file")
import("detect.tools.find_7z")
import("detect.tools.find_tar")
import("detect.tools.find_gzip")
import("detect.tools.find_unzip")

-- extract archivefile using tar
function _extract_using_tar(archivefile, outputdir, extension)

    -- the tar of winenv can only extract "*.tar"
    if os.host() == "windows" and extension ~= ".tar" then
        return false
    end

    -- find tar
    local program = find_tar()
    if not program then
        return false
    end

    -- init argv
    local argv = {ifelse(option.get("verbose"), "-xvf", "-xf"), archivefile}

    -- ensure output directory
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- set outputdir
    table.insert(argv, "-C")
    table.insert(argv, outputdir)

    -- extract it
    os.vrunv(program, argv)

    -- ok
    return true
end

-- extract archivefile using 7z
function _extract_using_7z(archivefile, outputdir, extension)

    -- find 7z
    local program = find_7z()
    if not program then
        return false
    end

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") then
        outputdir_old = outputdir
        outputdir = os.tmpfile() .. ".tar"
    end

    -- init argv
    local argv = {"x", "-y", ifelse(option.get("verbose"), "-bb3", "-bb0"), archivefile}

    -- ensure output directory
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- set outputdir
    table.insert(argv, "-o" .. outputdir)

    -- extract it
    os.vrunv(program, argv)

    -- continue to extract *.tar file
    if outputdir_old then
        local tarfile = find_file("*.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_tar, _extract_using_7z})
        end
    end

    -- ok
    return true
end

-- extract archivefile using gzip
function _extract_using_gzip(archivefile, outputdir, extension)

    -- find gzip
    local program = find_gzip()
    if not program then
        return false
    end

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") then
        outputdir_old = outputdir
        outputdir = os.tmpfile() .. ".tar"
    end

    -- init temporary archivefile
    local tmpfile = path.join(outputdir, path.filename(archivefile))

    -- init argv
    local argv = {"-d", "-f"}
    if not option.get("verbose") then
        table.insert(argv, "-q")
    end
    table.insert(argv, tmpfile)

    -- ensure output directory
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- copy archivefile to outputdir first
    if path.absolute(archivefile) ~= path.absolute(tmpfile) then
        os.cp(archivefile, tmpfile)
    end

    -- enter outputdir
    local oldir = os.cd(outputdir)

    -- extract it
    os.vrunv(program, argv)

    -- leave outputdir
    os.cd(oldir)

    -- continue to extract *.tar file
    if outputdir_old then
        local tarfile = find_file("*.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_tar, _extract_using_7z})
        end
    end

    -- ok
    return true
end

-- extract archivefile using unzip
function _extract_using_unzip(archivefile, outputdir, extension)

    -- find unzip
    local program = find_unzip()
    if not program then
        return false
    end

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") then
        outputdir_old = outputdir
        outputdir = os.tmpfile() .. ".tar"
    end

    -- init argv
    local argv = {}
    if option.get("verbose") then
        table.insert(argv, "-q")
    end
    table.insert(argv, archivefile)

    -- ensure output directory
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- extract to outputdir 
    table.insert(argv, "-d")
    table.insert(argv, outputdir)

    -- extract it
    os.vrunv(program, argv)

    -- continue to extract *.tar file
    if outputdir_old then
        local tarfile = find_file("*.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_tar, _extract_using_7z})
        end
    end

    -- ok
    return true
end

-- extract archive file using extractors
function _extract(archivefile, outputdir, extension, extractors)

    -- extract it
    for _, extract in ipairs(extractors) do
        if extract(archivefile, outputdir, extension) then
            return true
        end
    end

    -- failed
    return false
end

-- get the extension of the archive file
function _extension(archivefile, extractors)
 
    -- get archive file name
    local filename = path.filename(archivefile)

    -- get extension
    local extension = ""
    local i = filename:find_last(".", true)
    if i then

        -- get next extension if exists
        local p = filename:sub(1, i - 1):find_last(".", true)
        if p and extractors[filename:sub(p)] then i = p end

        -- ok
        extension = filename:sub(i)
    end

    -- ok?
    return extension
end

-- extract archive file
--
-- @param archivefile   the archive file. e.g. *.tar.gz, *.zip, *.7z, *.tar.bz2, ..
-- @param outputdir     the output directory
--
function main(archivefile, outputdir)

    -- init outputdir
    outputdir = outputdir or os.curdir()

    -- init extractors
    local extractors =
    {
        [".zip"]        = {_extract_using_unzip, _extract_using_tar, _extract_using_7z}
    ,   [".7z"]         = {_extract_using_7z}
    ,   [".gz"]         = {_extract_using_gzip, _extract_using_tar, _extract_using_7z}
    ,   [".bz2"]        = {_extract_using_tar, _extract_using_7z}
    ,   [".tar"]        = {_extract_using_tar, _extract_using_7z}
    ,   [".tar.gz"]     = {_extract_using_tar, _extract_using_gzip, _extract_using_7z}
    ,   [".tar.bz2"]    = {_extract_using_tar, _extract_using_7z}
    }
    
    -- get extension
    local extension = _extension(archivefile, extractors)

    -- extract it
    _extract(archivefile, outputdir, extension, extractors[extension])
end
